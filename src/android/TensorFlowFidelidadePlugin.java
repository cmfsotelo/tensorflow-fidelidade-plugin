package com.tensorflow.fidelidade.plugin;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Base64;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.AbstractMap;
import java.util.Map;
import java.util.PriorityQueue;

import ai.doc.tensorio.TIOLayerInterface.TIOVectorLayerDescription;
import ai.doc.tensorio.TIOModel.TIOModel;
import ai.doc.tensorio.TIOModel.TIOModelBundle;
import ai.doc.tensorio.TIOModel.TIOModelBundleManager;
import ai.doc.tensorio.TIOModel.TIOModelException;

/**
 * OutSystems Experts Team
 * <p>
 * Author: Paulo Cesar
 * Date: 18-12-2019
 */
public class TensorFlowFidelidadePlugin extends CordovaPlugin {

    private static final String TAG = TensorFlowFidelidadePlugin.class.getSimpleName();
    private TIOModel model;
    //Models (Enquadramento, Qualidade da Imagem)
    private static final String ENQ_MODEL = "enq_model";
    private static final String QUALITY_MODEL = "quality_model";
    private static final String UNET_VEHICLE_MODEL = "unet_vehicle_model";
    private static final String ACTION_LOAD_MODEL = "loadModel";

    static final String ENQ_KEY = "enquadramento";

    // Handler to execute in Second Thread
    // Create a background thread
    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

        if (action != null && action.equalsIgnoreCase(ACTION_LOAD_MODEL)) {

            if (args != null && args.length() > 0) {

                String modelName = args.getString(0);
                String imageBase64 = args.getString(1);

                if (modelName != null && imageBase64 != null) {
                    this.loadModel(modelName, imageBase64);
                } else {
                    this.callbackContext.error("Invalid or not found action!");
                }

            } else {
                this.callbackContext.error("The arguments can not be null!");
            }

        } else {
            this.callbackContext.error("Invalid or not found action!");
        }

        return true;

    }

    /**
     * Load model to Tensor Flow Lite to execute a function
     */
    private void loadModel(String modelName, String imageBase64) {
        try {

            TIOModelBundleManager manager = new TIOModelBundleManager(this.cordova.getActivity().getApplicationContext(), "");
            // load the model
            TIOModelBundle bundle = manager.bundleWithId(modelName);

            if (bundle == null) {
                this.callbackContext.error("Model can not find to load!");
                return;
            }

            model = bundle.newModel();
            model.load();

            //Convert base64 to bitmap image
            Bitmap image = this.convertBase64ToBitmap(imageBase64);

            // Model loaded success -- Resize Image
            Bitmap imageResized;


            // Switch to know what is the model will be executed.
            switch (modelName) {
                case ENQ_MODEL: {
                    imageResized = this.resizeImage(image, 64);
                    this.executeFrameworkModel(imageResized);
                    break;
                }

                case QUALITY_MODEL: {
                    imageResized = this.resizeImage(image, 224);
                    this.executeQualityModel(imageResized);
                    break;
                }

                case UNET_VEHICLE_MODEL: {
                    imageResized = this.resizeImage(image, 224);
                    this.executeUnetVehicleModel(imageResized);
                    break;
                }
            }

        } catch (Exception e) {
            this.callbackContext.error("Error to load a model with name " + modelName);
        }

    }

    private Bitmap convertBase64ToBitmap(String b64) {
        byte[] imageAsBytes = Base64.decode(b64.getBytes(), Base64.DEFAULT);
        return BitmapFactory.decodeByteArray(imageAsBytes, 0, imageAsBytes.length);
    }

    private synchronized Bitmap resizeImage(Bitmap img, int resizeImage) {

        try {

            if (img != null) {
                return Bitmap.createScaledBitmap(img, resizeImage, resizeImage, false);

            } else {
                this.callbackContext.error("Error to resize the image!");
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
            this.callbackContext.error(e.getMessage());
        }

        return null;
    }

    private void executeUnetVehicleModel(Bitmap imageResized) {
        this.cordova.getThreadPool().execute(() -> {
            // Run the model on the input
            Bitmap imageResult;

            try {
                imageResult = (Bitmap) model.runOn(imageResized);
                if (imageResult != null && imageResult.getWidth() > 0) {

                }

            } catch (Exception e) {
                callbackContext.error("Error to load or execute the Unet Vehicle model");
            }
        });
    }

    private void executeQualityModel(Bitmap imageResized) {
        this.cordova.getThreadPool().execute(() -> {
            // Run the model on the input
            float[] result;

            try {
                result = (float[]) model.runOn(imageResized);

                if (result.length > 0) {
                    if (result[0] > result[1]) {
                        callbackContext.success(String.valueOf(false));
                    } else {
                        callbackContext.success(String.valueOf(true));
                    }
                }

            } catch (Exception e) {
                callbackContext.error("Error to load or execute the quality model");
            }
        });
    }

    private void executeFrameworkModel(Bitmap imageResized) {
        this.cordova.getThreadPool().execute(() -> {
            // Run the model on the input
            float[] result = new float[0];

            try {
                result = (float[]) model.runOn(imageResized);
            } catch (TIOModelException e) {
                callbackContext.error("Error to execute the framework model");
            }

            // Build a PriorityQueue of the predictions
            PriorityQueue<Map.Entry<Integer, Float>> pq = new PriorityQueue<>(10, (o1, o2) -> (o2.getValue()).compareTo(o1.getValue()));
            for (int i = 0; i < 13; i++) {
                pq.add(new AbstractMap.SimpleEntry<>(i, result[i]));
            }

            try {
                // Show the 10 most likely predictions
                String[] labels = ((TIOVectorLayerDescription) model.descriptionOfOutputAtIndex(0)).getLabels();

                for (int i = 0; i < 1; i++) {

                    Map.Entry<Integer, Float> e = pq.poll();

                    if (e != null) {
                        callbackContext.success(labels[e.getKey()]);
                    }
                }

            } catch (Exception e) {
                callbackContext.error("Error to load or execute the framework model");
            }
        });
    }
}
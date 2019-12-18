TensorFlow Fidelidade Plugin
==============

Este plugin foi desenvolvido para a Fidelidade utiliznado a biblioteca do Google Tensor Flow lite para fazer o carregamento e execução de modelos pre-definidos pela Fidelidade para identificar Qualidade de Imagens e Enquadramento.

## Supported Platforms
* Android
* iOS

## Installing

Para instalar no Android deve seguir o modelo abaixo passando o minSdkVersion = 22 e targetSdkVersion = 28. Os valores informados nas variaveís são as versões de compatibilidade  para usar a Biblioteca do TensorFlow Lite

    $ cordova plugin add https://github.com/Paulimjr/tensorflow-fidelidade-plugin.git --variable ANDROID-MINSDKVERSION=22, --variable ANDROID-TARGETSDKVERSION=28


## Usage
Para executar o plugin na plataforma da OutSytems basta seguir o modelo abaixo

### Load model
```javascript
/**
 *  modelName o nome do modelo que deseja executar no plugin (Observações: os modelos já estão definidos dentro do plugin)
 *  imageBase64 a String com a imagem em base64 já enviar pela OutSystem utilize algum converter na Plataforma para fazer o mesmo.
 * /
cordova.plugins.TensorFlowFidelidadePlugin.loadModel(modelName, imageBase64,
    function success(data) {
        alert("Result: "+data.value);
    },
    function error(data) {
        alert("Error: "+data);
    }
);
```

## License
This plugin is distributed under the MIT License.

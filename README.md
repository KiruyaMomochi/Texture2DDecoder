# Texture2DDecoder

Decodes Unity's Texture2D assets to image.

The original code is from [Perfare/AssetStudio](https://github.com/Perfare/AssetStudio).
This project adds `CMakeLists.txt` to allow building with `cmake` on other platforms.

The wrapper is provided as a NuGet package. 

[![Wrapper Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder?color=9e4edf&label=Kyaru.Texture2DDecoder&logo=nuget&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder/)

We also provide native library package for the following platforms:

|Platform|NuGet Package|
|---|---|
|Windows|[![Windows Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.Windows?color=9e4edf&label=Kyaru.Texture2DDecoder.Windows&logo=microsoft&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.Windows/)|
|Linux|[![Linux Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.Linux?color=9e4edf&label=Kyaru.Texture2DDecoder.Linux&logo=linux&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.Linux/)|
|macOS|[![MacOS Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.MacOS?color=9e4edf&label=Kyaru.Texture2DDecoder.macOS&logo=apple&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.MacOS/)|
|Android|[![Android Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.Android?color=9e4edf&label=Kyaru.Texture2DDecoder.Android&logo=android&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.Android/)|
|iOS\*|[![iOS Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.iOS?color=9e4edf&label=Kyaru.Texture2DDecoder.iOS&logo=iOS&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.iOS/)|
|WebAssembly|[![WebAssembly Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.WebAssembly?color=9e4edf&label=Kyaru.Texture2DDecoder.WebAssembly&logo=webassembly&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.WebAssembly/)|
|MacCatalyst|[![MacCatalyst Package](https://img.shields.io/nuget/dt/Kyaru.Texture2DDecoder.MacCatalyst?color=9e4edf&label=Kyaru.Texture2DDecoder.MacCatalyst&logo=apple&logoColor=white)](https://www.nuget.org/packages/Kyaru.Texture2DDecoder.MacCatalyst/)|

\* iOS: only tested on simulator, not granted to work.

For how this package is built, and other details, see our [wiki](https://github.com/KiruyaMomochi/Texture2DDecoder/wiki).

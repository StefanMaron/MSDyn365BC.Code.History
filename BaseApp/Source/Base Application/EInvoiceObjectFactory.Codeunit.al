codeunit 10147 "E-Invoice Object Factory"
{

    trigger OnRun()
    begin
    end;

    procedure GetSignatureProvider(var ISignatureProvider: DotNet ISignatureProvider)
    var
        CFDISignatureProvider: DotNet CFDISignatureProvider;
    begin
        if IsNull(ISignatureProvider) then
            ISignatureProvider := CFDISignatureProvider.CFDISignatureProvider;
    end;

    procedure GetWebServiceInvoker(var IWebServiceInvoker: DotNet IWebServiceInvoker)
    var
        SOAPWebServiceInvoker: DotNet SOAPWebServiceInvoker;
    begin
        if IsNull(IWebServiceInvoker) then
            IWebServiceInvoker := SOAPWebServiceInvoker.SOAPWebServiceInvoker;
    end;

    procedure GetBarCodeProvider(var IBarCodeProvider: DotNet IBarcodeProvider)
    var
        QRCodeProvider: DotNet QRCodeProvider;
    begin
        if IsNull(IBarCodeProvider) then
            IBarCodeProvider := QRCodeProvider.QRCodeProvider;
    end;

    procedure GetBarCodeBlob(QRCodeInput: Text; var TempBLOB: Codeunit "Temp Blob")
    var
        IBarCodeProvider: DotNet IBarcodeProvider;
        BlobOutStr: OutStream;
    begin
        GetBarCodeProvider(IBarCodeProvider);
        TempBLOB.CreateOutStream(BlobOutStr);
        IBarCodeProvider.GetBarcodeStream(QRCodeInput, BlobOutStr);
    end;
}


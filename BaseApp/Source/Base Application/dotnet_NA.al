﻿dotnet
{
    assembly("Microsoft.Dynamics.Nav.MX")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider"; "IBarcodeProvider")
        {
        }

        type("Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider"; "QRCodeProvider")
        {
        }
        type("Microsoft.Dynamics.Nav.MX.SignatureProviders.CFDISignatureProvider"; "CFDISignatureProvider")
        {
        }
        type("Microsoft.Dynamics.Nav.MX.WebServiceInvokers.SOAPWebServiceInvoker"; "SOAPWebServiceInvoker")
        {
        }
    }
}
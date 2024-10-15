dotnet
{
    assembly("Microsoft.Dynamics.NL.Digipoortservice")
    {
        Version = '15.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.NL.DigipoortServices"; "DigipoortServices")
        {
        }

        type("Digipoort.AanleverService.aanleverRequest"; "aanleverRequest")
        {
        }

        type("Digipoort.AanleverService.aanleverResponse"; "aanleverResponse")
        {
        }

        type("Digipoort.AanleverService.identiteitType"; "identiteitType")
        {
        }

        type("Digipoort.AanleverService.berichtInhoudType"; "berichtInhoudType")
        {
        }

        type("Digipoort.AanleverService.foutType"; "foutType")
        {
        }

        type("Digipoort.StatusinformatieService.getStatussenProcesRequest"; "getStatussenProcesRequest")
        {
        }

        type("Digipoort.StatusinformatieService.StatusResultaat"; "StatusResultaat")
        {
        }
    }
}
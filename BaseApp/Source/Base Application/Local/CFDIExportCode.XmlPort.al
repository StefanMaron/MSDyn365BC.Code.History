xmlport 27004 "CFDI Export Code"
{

    schema
    {
        textelement("data-set-ExportCodes")
        {
            tableelement("CFDI Export Code"; "CFDI Export Code")
            {
                XmlName = 'ExportCode';
                fieldelement(Code; "CFDI Export Code".Code)
                {
                }
                fieldelement(Description; "CFDI Export Code".Description)
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}


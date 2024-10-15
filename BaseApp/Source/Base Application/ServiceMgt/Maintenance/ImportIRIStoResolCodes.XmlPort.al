namespace Microsoft.Service.Maintenance;

xmlport 5902 "Import IRIS to Resol. Codes"
{
    Caption = 'Import IRIS to Resol. Codes';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Resolution Code"; "Resolution Code")
            {
                XmlName = 'ResolutionCode';
                fieldelement(Code; "Resolution Code".Code)
                {
                }
                fieldelement(Description; "Resolution Code".Description)
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


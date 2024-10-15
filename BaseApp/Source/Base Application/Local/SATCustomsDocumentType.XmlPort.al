xmlport 27048 "SAT Customs Document Type"
{

    schema
    {
        textelement("data-set-CustomsDocuments")
        {
            tableelement("SAT Customs Document Type"; "SAT Customs Document Type")
            {
                XmlName = 'CustomsDocument';
                fieldelement(Code; "SAT Customs Document Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Customs Document Type".Description)
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


xmlport 27024 "SAT Hazardous Material"
{

    schema
    {
        textelement("data-set-MaterialPeligroso")
        {
            tableelement("SAT Hazardous Material"; "SAT Hazardous Material")
            {
                XmlName = 'c_MaterialsPeligroso';
                fieldelement(Code; "SAT Hazardous Material".Code)
                {
                }
                fieldelement(Descripcion; "SAT Hazardous Material".Description)
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


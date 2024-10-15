xmlport 27039 "SAT Material Type"
{

    schema
    {
        textelement("data-set-MaterialTypes")
        {
            tableelement("SAT Material Type"; "SAT Material Type")
            {
                XmlName = 'MaterialType';
                fieldelement(Code; "SAT Material Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Material Type".Description)
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


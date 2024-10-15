xmlport 27027 "SAT Municipality"
{

    schema
    {
        textelement("data-set-c_Municipio")
        {
            tableelement("SAT Municipality"; "SAT Municipality")
            {
                XmlName = 'Municipio';
                fieldelement(Code; "SAT Municipality".Code)
                {
                }
                fieldelement(State; "SAT Municipality".State)
                {
                }
                fieldelement(Descripcion; "SAT Municipality".Description)
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


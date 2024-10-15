xmlport 27026 "SAT State"
{

    schema
    {
        textelement("data-set-c_Estados")
        {
            tableelement("SAT State"; "SAT State")
            {
                XmlName = 'Estado';
                fieldelement(Code; "SAT State".Code)
                {
                }
                fieldelement(Descripcion; "SAT State".Description)
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


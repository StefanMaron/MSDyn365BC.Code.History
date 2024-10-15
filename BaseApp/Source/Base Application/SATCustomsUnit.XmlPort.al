xmlport 27046 "SAT Customs Unit"
{

    schema
    {
        textelement("data-set-CustomUnits")
        {
            tableelement("SAT Customs Unit"; "SAT Customs Unit")
            {
                XmlName = 'c_CustomUnit';
                fieldelement(Code; "SAT Customs Unit".Code)
                {
                }
                fieldelement(Descripcion; "SAT Customs Unit".Description)
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


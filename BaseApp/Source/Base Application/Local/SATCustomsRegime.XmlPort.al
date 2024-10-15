xmlport 27047 "SAT Customs Regime"
{

    schema
    {
        textelement("data-set-CustomsRegimes")
        {
            tableelement("SAT Customs Regime"; "SAT Customs Regime")
            {
                XmlName = 'CustomsRegime';
                fieldelement(Code; "SAT Customs Regime".Code)
                {
                }
                fieldelement(Descripcion; "SAT Customs Regime".Description)
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


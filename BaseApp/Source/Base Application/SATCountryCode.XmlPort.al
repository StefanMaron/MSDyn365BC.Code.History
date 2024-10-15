xmlport 27014 "SAT Country Code"
{
    Caption = 'SAT Country Code';

    schema
    {
        textelement("data-set-ResidenciaFiscal")
        {
            tableelement("SAT Country Code"; "SAT Country Code")
            {
                XmlName = 'c_ResidenciaFiscals';
                fieldelement(c_Pais; "SAT Country Code"."SAT Country Code")
                {
                }
                fieldelement(Descripcion; "SAT Country Code".Description)
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


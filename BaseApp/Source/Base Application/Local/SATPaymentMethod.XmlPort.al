xmlport 27015 "SAT Payment Method"
{
    Caption = 'SAT Payment Method';

    schema
    {
        textelement("data-set-FormaPago")
        {
            tableelement("SAT Payment Method"; "SAT Payment Method")
            {
                XmlName = 'c_FormaPagos';
                fieldelement(c_FormaPago; "SAT Payment Method".Code)
                {
                }
                fieldelement(Descripcion; "SAT Payment Method".Description)
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


xmlport 27013 "SAT Unit of Measure"
{
    Caption = 'SAT Unit of Measure';

    schema
    {
        textelement("data-set-ClaveUnidad")
        {
            tableelement("SAT Unit of Measure"; "SAT Unit of Measure")
            {
                XmlName = 'c_ClaveUnidads';
                fieldelement(c_ClaveUnidad; "SAT Unit of Measure"."SAT UofM Code")
                {
                }
                fieldelement(Nombre; "SAT Unit of Measure".Name)
                {
                }
                fieldelement(Descripcion; "SAT Unit of Measure".Description)
                {
                }
                fieldelement(Simbolo; "SAT Unit of Measure".Symbol)
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


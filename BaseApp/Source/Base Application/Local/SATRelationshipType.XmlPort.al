xmlport 27011 "SAT Relationship Type"
{
    Caption = 'SAT Relationship Type';

    schema
    {
        textelement("data-set-c_TipoRelacion")
        {
            tableelement("SAT Relationship Type"; "SAT Relationship Type")
            {
                XmlName = 'c_TipoRelacions';
                fieldelement(c_TipoRelacion; "SAT Relationship Type"."SAT Relationship Type")
                {
                }
                fieldelement(Descripcion; "SAT Relationship Type".Description)
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


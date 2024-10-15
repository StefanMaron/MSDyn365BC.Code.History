xmlport 27022 "SAT Trailer Type"
{

    schema
    {
        textelement("data-set-TipoDeRemolque")
        {
            tableelement("SAT Trailer Type"; "SAT Trailer Type")
            {
                XmlName = 'c_TipoRemolques';
                fieldelement(Code; "SAT Trailer Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Trailer Type".Description)
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


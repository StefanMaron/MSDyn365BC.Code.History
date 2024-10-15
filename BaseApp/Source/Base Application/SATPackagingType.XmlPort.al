xmlport 27025 "SAT Packaging Type"
{

    schema
    {
        textelement("data-set-TipoDeEmbalaje")
        {
            tableelement("SAT Packaging Type"; "SAT Packaging Type")
            {
                XmlName = 'c_TiposEmbalaje';
                fieldelement(Code; "SAT Packaging Type".Code)
                {
                }
                fieldelement(Descripcion; "SAT Packaging Type".Description)
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


xmlport 27016 "SAT Tax Scheme"
{
    Caption = 'SAT Tax Scheme';

    schema
    {
        textelement("data-set-RegimenFiscal")
        {
            tableelement("SAT Tax Scheme"; "SAT Tax Scheme")
            {
                XmlName = 'c_RegimenFiscals';
                fieldelement(c_RegimenFiscal; "SAT Tax Scheme"."SAT Tax Scheme")
                {
                }
                fieldelement(Descripcion; "SAT Tax Scheme".Description)
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


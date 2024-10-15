xmlport 27003 "CFDI Cancellation Reason"
{

    schema
    {
        textelement("data-set-CancellationReason")
        {
            tableelement("CFDI Cancellation Reason"; "CFDI Cancellation Reason")
            {
                XmlName = 'Motivo';
                fieldelement(Code; "CFDI Cancellation Reason".Code)
                {
                }
                fieldelement(Descripcion; "CFDI Cancellation Reason".Description)
                {
                }
                fieldelement(SubstitutionRequired; "CFDI Cancellation Reason"."Substitution Number Required")
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


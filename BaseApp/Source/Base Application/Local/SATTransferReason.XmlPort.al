xmlport 27038 "SAT Transfer Reason"
{

    schema
    {
        textelement("data-set-TransferReasons")
        {
            tableelement("SAT Transfer Reason"; "SAT Transfer Reason")
            {
                XmlName = 'TransferReason';
                fieldelement(Code; "SAT Transfer Reason".Code)
                {
                }
                fieldelement(Descripcion; "SAT Transfer Reason".Description)
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


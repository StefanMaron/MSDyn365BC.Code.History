﻿xmlport 27008 "CFDI Subject to Tax"
{

    schema
    {
        textelement("data-set-SubjectToTax")
        {
            tableelement("CFDI Subject to Tax"; "CFDI Subject to Tax")
            {
                XmlName = 'ObjetoImp';
                fieldelement(Code; "CFDI Subject to Tax".Code)
                {
                }
                fieldelement(Descripcion; "CFDI Subject to Tax".Description)
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


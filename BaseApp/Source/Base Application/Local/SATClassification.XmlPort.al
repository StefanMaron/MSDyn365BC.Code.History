xmlport 27010 "SAT Classification"
{
    Caption = 'SAT Classification';

    schema
    {
        textelement("data-set-ClaveProdServ")
        {
            tableelement("SAT Classification"; "SAT Classification")
            {
                XmlName = 'c_ClaveProdServs';
                fieldelement(c_ClaveProdServ; "SAT Classification"."SAT Classification")
                {
                }
                fieldelement(Descripcion; "SAT Classification".Description)
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


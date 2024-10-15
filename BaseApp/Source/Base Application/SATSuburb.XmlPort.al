xmlport 27029 "SAT Suburb"
{

    schema
    {
        textelement("data-set-c_Colonias")
        {
            tableelement("SAT Suburb"; "SAT Suburb")
            {
                XmlName = 'Colonia';
                fieldelement(Code; "SAT Suburb"."Suburb Code")
                {
                }
                fieldelement(PostCode; "SAT Suburb"."Postal Code")
                {
                }
                fieldelement(Descripcion; "SAT Suburb".Description)
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    EntryNo += 1;
                    "SAT Suburb".ID := EntryNo;
                end;
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

    var
        EntryNo: Integer;
}


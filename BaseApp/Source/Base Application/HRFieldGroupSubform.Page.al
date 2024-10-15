page 17364 "HR Field Group Subform"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "HR Field Group Line";
    SourceTableView = SORTING("Field Group Code", "Field Print Order No.", "Table No.", "Field No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Table No."; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Field Report Caption"; "Field Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        HRFieldGroupLine: Record "HR Field Group Line";
        OrderNo: Integer;
    begin
        HRFieldGroupLine.SetCurrentKey("Field Group Code",
          "Field Print Order No.", "Table No.", "Field No.");
        HRFieldGroupLine.SetRange("Field Group Code", "Field Group Code");

        if BelowxRec then begin
            if HRFieldGroupLine.Find('+') then;
            "Field Print Order No." := HRFieldGroupLine."Field Print Order No." + 1;
        end else begin
            OrderNo := xRec."Field Print Order No.";

            HRFieldGroupLine.SetFilter("Field Print Order No.", '%1..', OrderNo);
            if HRFieldGroupLine.Find('+') then
                repeat
                    HRFieldGroupLine."Field Print Order No." += 1;
                    HRFieldGroupLine.Modify;
                until HRFieldGroupLine.Next(-1) = 0;
            "Field Print Order No." := OrderNo;
        end;
    end;
}


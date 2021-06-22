report 7306 "Get Inbound Source Documents"
{
    Caption = 'Get Inbound Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Whse. Put-away Request"; "Whse. Put-away Request")
        {
            DataItemTableView = WHERE("Completely Put Away" = CONST(false));
            RequestFilterFields = "Document Type", "Document No.";
            dataitem("Posted Whse. Receipt Header"; "Posted Whse. Receipt Header")
            {
                DataItemLink = "No." = FIELD("Document No.");
                DataItemTableView = SORTING("No.");
                dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    DataItemTableView = SORTING("No.", "Line No.");

                    trigger OnPreDataItem()
                    begin
                        OnPostedWhseReceiptLineOnPreDataItem("Posted Whse. Receipt Line");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Put-away Qty.", "Put-away Qty. (Base)");
                        if "Qty. (Base)" > "Qty. Put Away (Base)" + "Put-away Qty. (Base)" then begin
                            if WhseWkshCreate.FromWhseRcptLine(
                                 WhseWkshTemplateName, WhseWkshName, LocationCode, "Posted Whse. Receipt Line")
                            then
                                LineCreated := true;
                        end;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Put-away Request"."Document Type" <>
                       "Whse. Put-away Request"."Document Type"::Receipt
                    then
                        CurrReport.Break();
                end;
            }
            dataitem("Whse. Internal Put-away Header"; "Whse. Internal Put-away Header")
            {
                DataItemLink = "No." = FIELD("Document No.");
                DataItemTableView = SORTING("No.");
                dataitem("Whse. Internal Put-away Line"; "Whse. Internal Put-away Line")
                {
                    DataItemLink = "No." = FIELD("No.");
                    DataItemTableView = SORTING("No.", "Line No.");

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Put-away Qty.", "Put-away Qty. (Base)");
                        if "Qty. (Base)" > "Qty. Put Away (Base)" + "Put-away Qty. (Base)" then begin
                            if WhseWkshCreate.FromWhseInternalPutawayLine(
                                 WhseWkshTemplateName, WhseWkshName, LocationCode, "Whse. Internal Put-away Line")
                            then
                                LineCreated := true;
                        end;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if "Whse. Put-away Request"."Document Type" <>
                       "Whse. Put-away Request"."Document Type"::"Internal Put-away"
                    then
                        CurrReport.Break();
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

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not HideDialog then
            if not LineCreated then
                Error(Text000);
    end;

    trigger OnPreReport()
    begin
        LineCreated := false;
    end;

    var
        Text000: Label 'There are no Warehouse Worksheet Lines created.';
        WhseWkshCreate: Codeunit "Whse. Worksheet-Create";
        WhseWkshTemplateName: Code[10];
        WhseWkshName: Code[10];
        LocationCode: Code[10];
        LineCreated: Boolean;
        HideDialog: Boolean;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetWhseWkshName(WhseWkshTemplateName2: Code[10]; WhseWkshName2: Code[10]; LocationCode2: Code[10])
    begin
        WhseWkshTemplateName := WhseWkshTemplateName2;
        WhseWkshName := WhseWkshName2;
        LocationCode := LocationCode2;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostedWhseReceiptLineOnPreDataItem(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line");
    begin
    end;
}


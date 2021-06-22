table 5912 "Service Document Log"
{
    Caption = 'Service Document Log';
    DrillDownPageID = "Service Document Log";
    LookupPageID = "Service Document Log";
    ReplicateData = true;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF ("Document Type" = CONST(Quote)) "Service Header"."No." WHERE("Document Type" = CONST(Quote))
            ELSE
            IF ("Document Type" = CONST(Order)) "Service Header"."No." WHERE("Document Type" = CONST(Order))
            ELSE
            IF ("Document Type" = CONST(Invoice)) "Service Header"."No." WHERE("Document Type" = CONST(Invoice))
            ELSE
            IF ("Document Type" = CONST("Credit Memo")) "Service Header"."No." WHERE("Document Type" = CONST("Credit Memo"))
            ELSE
            IF ("Document Type" = CONST(Shipment)) "Service Shipment Header"
            ELSE
            IF ("Document Type" = CONST("Posted Invoice")) "Service Invoice Header"
            ELSE
            IF ("Document Type" = CONST("Posted Credit Memo")) "Service Cr.Memo Header";
            ValidateTableRelation = false;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Event No."; Integer)
        {
            Caption = 'Event No.';
        }
        field(4; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
        }
        field(5; After; Text[50])
        {
            Caption = 'After';
        }
        field(6; Before; Text[50])
        {
            Caption = 'Before';
        }
        field(7; "Change Date"; Date)
        {
            Caption = 'Change Date';
        }
        field(8; "Change Time"; Time)
        {
            Caption = 'Change Time';
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(10; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Shipment,Posted Invoice,Posted Credit Memo';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo",Shipment,"Posted Invoice","Posted Credit Memo";
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Change Date", "Change Time")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ServOrderLog.Reset();
        ServOrderLog.SetRange("Document Type", "Document Type");
        ServOrderLog.SetRange("Document No.", "Document No.");
        if ServOrderLog.FindLast then
            "Entry No." := ServOrderLog."Entry No." + 1
        else
            "Entry No." := 1;

        "Change Date" := Today;
        "Change Time" := Time;
        "User ID" := UserId;
    end;

    var
        ServOrderLog: Record "Service Document Log";

    procedure CopyServLog(DocType: Option; DocNo: Code[20])
    var
        ServDocLog: Record "Service Document Log";
    begin
        ServDocLog.Reset();
        ServDocLog.SetRange("Document Type", DocType);
        ServDocLog.SetRange("Document No.", DocNo);
        if ServDocLog.FindSet then
            repeat
                Rec := ServDocLog;
                Insert;
            until ServDocLog.Next = 0;
    end;

    local procedure FillTempServDocLog(var ServHeader: Record "Service Header"; var TempServDocLog: Record "Service Document Log" temporary)
    var
        ServDocLog: Record "Service Document Log";
    begin
        with ServHeader do begin
            TempServDocLog.Reset();
            TempServDocLog.DeleteAll();

            if "No." <> '' then begin
                TempServDocLog.CopyServLog("Document Type", "No.");
                TempServDocLog.CopyServLog(ServDocLog."Document Type"::Shipment, "No.");
                TempServDocLog.CopyServLog(ServDocLog."Document Type"::"Posted Invoice", "No.");
                TempServDocLog.CopyServLog(ServDocLog."Document Type"::"Posted Credit Memo", "No.");
            end;

            TempServDocLog.Reset();
            TempServDocLog.SetCurrentKey("Change Date", "Change Time");
            TempServDocLog.Ascending(false);
        end;
    end;

    procedure ShowServDocLog(var ServHeader: Record "Service Header")
    var
        TempServDocLog: Record "Service Document Log" temporary;
    begin
        FillTempServDocLog(ServHeader, TempServDocLog);
        PAGE.Run(0, TempServDocLog);
    end;
}


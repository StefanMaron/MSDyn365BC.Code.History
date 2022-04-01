table 99000849 "Action Message Entry"
{
    Caption = 'Action Message Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Type; Enum "Action Message Type")
        {
            Caption = 'Type';
        }
        field(3; "Reservation Entry"; Integer)
        {
            Caption = 'Reservation Entry';
            TableRelation = "Reservation Entry"."Entry No.";
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "New Date"; Date)
        {
            Caption = 'New Date';
        }
        field(6; Calculation; Option)
        {
            Caption = 'Calculation';
            OptionCaption = 'Sum,None';
            OptionMembers = "Sum","None";
        }
        field(7; "Suppressed Action Msg."; Boolean)
        {
            Caption = 'Suppressed Action Msg.';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(16; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(17; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(18; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
        }
        field(19; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Reservation Entry", Calculation)
        {
            SumIndexFields = Quantity;
        }
        key(Key3; "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.", "Item No.", "Location Code", "Bin Code", "Variant Code")
        {
            SumIndexFields = Quantity;
        }
    }

    fieldgroups
    {
    }

    var
        ComponentBinding: Boolean;
        FirstDate: Date;
        FirstTime: Time;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure SumUp(var ActionMessageEntry: Record "Action Message Entry")
    var
        ActionMessageEntry2: Record "Action Message Entry";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ProdOrderComp: Record "Prod. Order Component";
        TypeArray: array[5] of Boolean;
    begin
        ActionMessageEntry2 := ActionMessageEntry;

        with ActionMessageEntry2 do begin
            SetSourceFilterFromActionEntry(Rec);
            SetRange("Location Code", "Location Code");
            SetRange("Bin Code", "Bin Code");
            SetRange("Variant Code", "Variant Code");
            SetRange("Item No.", "Item No.");
            ActionMessageEntry."New Date" := 0D;
            ActionMessageEntry.Quantity := 0;
            ActionMessageEntry.Type := ActionMessageEntry.Type::" ";
            if FindSet() then
                repeat
                    if Quantity <> 0 then begin
                        ActionMessageEntry.Quantity += Quantity;
                        TypeArray[2] := true;
                    end;
                    if "New Date" <> 0D then begin
                        ActionMessageEntry."New Date" := "New Date";
                        TypeArray[3] := true;
                    end;
                until Next() = 0;

            if TypeArray[2] then
                ActionMessageEntry.Type := ActionMessageEntry.Type::"Change Qty.";

            if TypeArray[3] then
                ActionMessageEntry.Type := ActionMessageEntry.Type::Reschedule;

            if TypeArray[2] and TypeArray[3] then
                ActionMessageEntry.Type := ActionMessageEntry.Type::"Resched. & Chg. Qty.";

            if TypeArray[1] then
                ActionMessageEntry.Type := ActionMessageEntry.Type::New;

            if TypeArray[5] then
                ActionMessageEntry.Type := ActionMessageEntry.Type::Cancel;

            "New Date" := ActionMessageEntry."New Date";
            Quantity := ActionMessageEntry.Quantity;
            Type := ActionMessageEntry.Type;
            ActionMessageEntry := ActionMessageEntry2;

            ComponentBinding := false;
            if ActionMessageEntry."Source Type" = DATABASE::"Prod. Order Line" then begin
                FirstDate := DMY2Date(31, 12, 9999);
                ActionMessageEntry.FilterToReservEntry(ReservEntry);
                ReservEntry.SetRange(Binding, ReservEntry.Binding::"Order-to-Order");
                if ReservEntry.FindSet() then
                    repeat
                        if ReservEntry2.Get(ReservEntry."Entry No.", false) then
                            if (ReservEntry2."Source Type" = DATABASE::"Prod. Order Component") and
                               (ReservEntry2."Source Subtype" = ReservEntry."Source Subtype") and
                               (ReservEntry2."Source ID" = ReservEntry."Source ID")
                            then
                                if ProdOrderComp.Get(
                                     ReservEntry2."Source Subtype", ReservEntry2."Source ID",
                                     ReservEntry2."Source Prod. Order Line", ReservEntry2."Source Ref. No.")
                                then begin
                                    ComponentBinding := true;
                                    if ProdOrderComp."Due Date" < FirstDate then begin
                                        FirstDate := ProdOrderComp."Due Date";
                                        FirstTime := ProdOrderComp."Due Time";
                                    end;
                                end;
                    until ReservEntry.Next() = 0;
            end;
        end;
    end;

    procedure TransferFromReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        "Reservation Entry" := ReservEntry."Entry No.";
        SetSourceFromReservEntry(ReservEntry);
        "Location Code" := ReservEntry."Location Code";
        "Variant Code" := ReservEntry."Variant Code";
        "Item No." := ReservEntry."Item No.";
    end;

    procedure FilterFromReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        SetSourceFilterFromReservEntry(ReservEntry);
        SetRange("Location Code", ReservEntry."Location Code");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Item No.", ReservEntry."Item No.");
    end;

    procedure FilterToReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
        ReservEntry.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
    end;

    procedure BoundToComponent(): Boolean
    begin
        exit(ComponentBinding);
    end;

    procedure ComponentDueDate(): Date
    begin
        exit(FirstDate);
    end;

    procedure ComponentDueTime(): Time
    begin
        exit(FirstTime);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Source Type" := ReservEntry."Source Type";
        "Source Subtype" := ReservEntry."Source Subtype";
        "Source ID" := ReservEntry."Source ID";
        "Source Ref. No." := ReservEntry."Source Ref. No.";
        "Source Batch Name" := ReservEntry."Source Batch Name";
        "Source Prod. Order Line" := ReservEntry."Source Prod. Order Line";
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);
        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetSourceFilterFromActionEntry(ActionMessageEntry: Record "Action Message Entry")
    begin
        SetRange("Source Type", ActionMessageEntry."Source Type");
        SetRange("Source Subtype", ActionMessageEntry."Source Subtype");
        SetRange("Source ID", ActionMessageEntry."Source ID");
        SetRange("Source Ref. No.", ActionMessageEntry."Source Ref. No.");
        SetRange("Source Batch Name", ActionMessageEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ActionMessageEntry."Source Prod. Order Line");
    end;

    procedure SetSourceFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Source Type", ReservEntry."Source Type");
        SetRange("Source Subtype", ReservEntry."Source Subtype");
        SetRange("Source ID", ReservEntry."Source ID");
        SetRange("Source Ref. No.", ReservEntry."Source Ref. No.");
        SetRange("Source Batch Name", ReservEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ReservEntry."Source Prod. Order Line");
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source ID");
        SetRange("Source Batch Name");
        SetRange("Source Prod. Order Line");
        SetRange("Source Ref. No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var ActionMessageEntry: Record "Action Message Entry"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;
}


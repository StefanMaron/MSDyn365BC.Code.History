codeunit 378 "Transfer Extended Text"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'There is not enough space to insert extended text lines.';
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        TempExtTextLine: Record "Extended Text Line" temporary;
        NextLineNo: Integer;
        LineSpacing: Integer;
        MakeUpdateRequired: Boolean;
        AutoText: Boolean;

    procedure SalesCheckIfAnyExtText(var SalesLine: Record "Sales Line"; Unconditionally: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(SalesLine."Line No.", SalesLine."No.", SalesLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteSalesLines(SalesLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case SalesLine.Type of
                SalesLine.Type::" ":
                    AutoText := true;
                SalesLine.Type::"G/L Account":
                    begin
                        if GLAcc.Get(SalesLine."No.") then
                            AutoText := GLAcc."Automatic Ext. Texts";
                    end;
                SalesLine.Type::Item:
                    begin
                        if Item.Get(SalesLine."No.") then
                            AutoText := Item."Automatic Ext. Texts";
                    end;
                SalesLine.Type::Resource:
                    begin
                        if Res.Get(SalesLine."No.") then
                            AutoText := Res."Automatic Ext. Texts";
                    end;
            end;

        OnSalesCheckIfAnyExtTextOnBeforeSetFilters(SalesLine, AutoText);

        if AutoText then begin
            SalesLine.TestField("Document No.");
            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
            ExtTextHeader.SetRange("Table Name", SalesLine.Type.AsInteger());
            ExtTextHeader.SetRange("No.", SalesLine."No.");
            case SalesLine."Document Type" of
                SalesLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Sales Quote", true);
                SalesLine."Document Type"::"Blanket Order":
                    ExtTextHeader.SetRange("Sales Blanket Order", true);
                SalesLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Sales Order", true);
                SalesLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Sales Invoice", true);
                SalesLine."Document Type"::"Return Order":
                    ExtTextHeader.SetRange("Sales Return Order", true);
                SalesLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Sales Credit Memo", true);
            end;
            OnSalesCheckIfAnyExtTextAutoText(ExtTextHeader, SalesHeader, SalesLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, SalesHeader."Document Date", SalesHeader."Language Code"));
        end;
    end;

    procedure ReminderCheckIfAnyExtText(var ReminderLine: Record "Reminder Line"; Unconditionally: Boolean): Boolean
    var
        ReminderHeader: Record "Reminder Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(ReminderLine."Line No.", ReminderLine."No.", ReminderLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteReminderLines(ReminderLine);

        if Unconditionally then
            AutoText := true
        else
            case ReminderLine.Type of
                ReminderLine.Type::" ":
                    AutoText := true;
                ReminderLine.Type::"G/L Account":
                    if GLAcc.Get(ReminderLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        if AutoText then begin
            ReminderLine.TestField("Reminder No.");
            ReminderHeader.Get(ReminderLine."Reminder No.");
            ExtTextHeader.SetRange("Table Name", ReminderLine.Type);
            ExtTextHeader.SetRange("No.", ReminderLine."No.");
            ExtTextHeader.SetRange(Reminder, true);
            OnReminderCheckIfAnyExtTextAutoText(ExtTextHeader, ReminderHeader, ReminderLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, ReminderHeader."Document Date", ReminderHeader."Language Code"));
        end;
    end;

    procedure FinChrgMemoCheckIfAnyExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line"; Unconditionally: Boolean): Boolean
    var
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(FinChrgMemoLine."Line No.", FinChrgMemoLine."No.", FinChrgMemoLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteFinChrgMemoLines(FinChrgMemoLine);

        if Unconditionally then
            AutoText := true
        else
            case FinChrgMemoLine.Type of
                FinChrgMemoLine.Type::" ":
                    AutoText := true;
                FinChrgMemoLine.Type::"G/L Account":
                    if GLAcc.Get(FinChrgMemoLine."No.") then
                        AutoText := GLAcc."Automatic Ext. Texts";
            end;

        if AutoText then begin
            FinChrgMemoLine.TestField("Finance Charge Memo No.");
            FinChrgMemoHeader.Get(FinChrgMemoLine."Finance Charge Memo No.");
            ExtTextHeader.SetRange("Table Name", FinChrgMemoLine.Type);
            ExtTextHeader.SetRange("No.", FinChrgMemoLine."No.");
            ExtTextHeader.SetRange("Finance Charge Memo", true);
            OnFinChrgMemoCheckIfAnyExtTextAutoText(ExtTextHeader, FinChrgMemoHeader, FinChrgMemoLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, FinChrgMemoHeader."Document Date", FinChrgMemoHeader."Language Code"));
        end;
    end;

    procedure PurchCheckIfAnyExtText(var PurchLine: Record "Purchase Line"; Unconditionally: Boolean): Boolean
    var
        PurchHeader: Record "Purchase Header";
        ExtTextHeader: Record "Extended Text Header";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(PurchLine."Line No.", PurchLine."No.", PurchLine."Attached to Line No.") then
            MakeUpdateRequired := DeletePurchLines(PurchLine);

        AutoText := false;

        if Unconditionally then
            AutoText := true
        else
            case PurchLine.Type of
                PurchLine.Type::" ":
                    AutoText := true;
                PurchLine.Type::"G/L Account":
                    begin
                        if GLAcc.Get(PurchLine."No.") then
                            AutoText := GLAcc."Automatic Ext. Texts";
                    end;
                PurchLine.Type::Item:
                    begin
                        if Item.Get(PurchLine."No.") then
                            AutoText := Item."Automatic Ext. Texts";
                    end;
                PurchLine.Type::Resource:
                    if Res.Get(PurchLine."No.") then
                        AutoText := Res."Automatic Ext. Texts";
            end;

        OnPurchCheckIfAnyExtTextOnBeforeSetFilters(PurchLine, AutoText);

        if AutoText then begin
            PurchLine.TestField("Document No.");
            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
            ExtTextHeader.SetRange("Table Name", PurchLine.Type.AsInteger());
            ExtTextHeader.SetRange("No.", PurchLine."No.");
            case PurchLine."Document Type" of
                PurchLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Purchase Quote", true);
                PurchLine."Document Type"::"Blanket Order":
                    ExtTextHeader.SetRange("Purchase Blanket Order", true);
                PurchLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Purchase Order", true);
                PurchLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Purchase Invoice", true);
                PurchLine."Document Type"::"Return Order":
                    ExtTextHeader.SetRange("Purchase Return Order", true);
                PurchLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Purchase Credit Memo", true);
            end;
            OnPurchCheckIfAnyExtTextAutoText(ExtTextHeader, PurchHeader, PurchLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, PurchHeader."Document Date", PurchHeader."Language Code"));
        end;
    end;

    procedure PrepmtGetAnyExtText(GLAccNo: Code[20]; TabNo: Integer; DocumentDate: Date; LanguageCode: Code[10]; var ExtTextLine: Record "Extended Text Line" temporary)
    var
        GLAcc: Record "G/L Account";
        ExtTextHeader: Record "Extended Text Header";
    begin
        ExtTextLine.DeleteAll();

        GLAcc.Get(GLAccNo);
        if not GLAcc."Automatic Ext. Texts" then
            exit;

        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
        ExtTextHeader.SetRange("No.", GLAccNo);
        case TabNo of
            DATABASE::"Sales Invoice Line":
                ExtTextHeader.SetRange("Prepmt. Sales Invoice", true);
            DATABASE::"Sales Cr.Memo Line":
                ExtTextHeader.SetRange("Prepmt. Sales Credit Memo", true);
            DATABASE::"Purch. Inv. Line":
                ExtTextHeader.SetRange("Prepmt. Purchase Invoice", true);
            DATABASE::"Purch. Cr. Memo Line":
                ExtTextHeader.SetRange("Prepmt. Purchase Credit Memo", true);
        end;
        OnPrepmtGetAnyExtTextBeforeReadLines(ExtTextHeader, DocumentDate, LanguageCode);
        if ReadLines(ExtTextHeader, DocumentDate, LanguageCode) then begin
            OnPrepmtGetAnyExtTextAfterReadLines(ExtTextHeader, TempExtTextLine);
            TempExtTextLine.Find('-');
            repeat
                ExtTextLine := TempExtTextLine;
                ExtTextLine.Insert();
            until TempExtTextLine.Next = 0;
        end;
    end;

    procedure InsertSalesExtText(var SalesLine: Record "Sales Line")
    var
        DummySalesLine: Record "Sales Line";
    begin
        InsertSalesExtTextRetLast(SalesLine, DummySalesLine);
    end;

    procedure InsertSalesExtTextRetLast(var SalesLine: Record "Sales Line"; var LastInsertedSalesLine: Record "Sales Line")
    var
        ToSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertSalesExtText(SalesLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToSalesLine.Reset();
        ToSalesLine.SetRange("Document Type", SalesLine."Document Type");
        ToSalesLine.SetRange("Document No.", SalesLine."Document No.");
        ToSalesLine := SalesLine;
        if ToSalesLine.Find('>') then begin
            LineSpacing :=
              (ToSalesLine."Line No." - SalesLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := SalesLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToSalesLine.Init();
                ToSalesLine."Document Type" := SalesLine."Document Type";
                ToSalesLine."Document No." := SalesLine."Document No.";
                ToSalesLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToSalesLine.Description := TempExtTextLine.Text;
                ToSalesLine."Attached to Line No." := SalesLine."Line No.";
                OnBeforeToSalesLineInsert(ToSalesLine, SalesLine, TempExtTextLine, NextLineNo, LineSpacing);
                ToSalesLine.Insert();
            until TempExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedSalesLine := ToSalesLine;
    end;

    procedure InsertReminderExtText(var ReminderLine: Record "Reminder Line")
    var
        ToReminderLine: Record "Reminder Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertReminderExtText(ReminderLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToReminderLine.Reset();
        ToReminderLine.SetRange("Reminder No.", ReminderLine."Reminder No.");
        ToReminderLine := ReminderLine;
        if ToReminderLine.Find('>') then begin
            LineSpacing :=
              (ToReminderLine."Line No." - ReminderLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := ReminderLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToReminderLine.Init();
                ToReminderLine."Reminder No." := ReminderLine."Reminder No.";
                ToReminderLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToReminderLine.Description := TempExtTextLine.Text;
                ToReminderLine."Attached to Line No." := ReminderLine."Line No.";
                ToReminderLine."Line Type" := ReminderLine."Line Type";
                OnBeforeToReminderLineInsert(ToReminderLine, ReminderLine, TempExtTextLine);
                ToReminderLine.Insert();
            until TempExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    procedure InsertFinChrgMemoExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line")
    var
        ToFinChrgMemoLine: Record "Finance Charge Memo Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertFinChrgMemoExtText(FinChrgMemoLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToFinChrgMemoLine.Reset();
        ToFinChrgMemoLine.SetRange("Finance Charge Memo No.", FinChrgMemoLine."Finance Charge Memo No.");
        ToFinChrgMemoLine := FinChrgMemoLine;
        if ToFinChrgMemoLine.Find('>') then begin
            LineSpacing :=
              (ToFinChrgMemoLine."Line No." - FinChrgMemoLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := FinChrgMemoLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToFinChrgMemoLine.Init();
                ToFinChrgMemoLine."Finance Charge Memo No." := FinChrgMemoLine."Finance Charge Memo No.";
                ToFinChrgMemoLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToFinChrgMemoLine.Description := TempExtTextLine.Text;
                ToFinChrgMemoLine."Attached to Line No." := FinChrgMemoLine."Line No.";
                ToFinChrgMemoLine.Insert();
            until TempExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    procedure InsertPurchExtText(var PurchLine: Record "Purchase Line")
    var
        DummyPurchLine: Record "Purchase Line";
    begin
        InsertPurchExtTextRetLast(PurchLine, DummyPurchLine);
    end;

    procedure InsertPurchExtTextRetLast(var PurchLine: Record "Purchase Line"; var LastInsertedPurchLine: Record "Purchase Line")
    var
        ToPurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertPurchExtText(PurchLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToPurchLine.Reset();
        ToPurchLine.SetRange("Document Type", PurchLine."Document Type");
        ToPurchLine.SetRange("Document No.", PurchLine."Document No.");
        ToPurchLine := PurchLine;
        if ToPurchLine.Find('>') then begin
            LineSpacing :=
              (ToPurchLine."Line No." - PurchLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := PurchLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToPurchLine.Init();
                ToPurchLine."Document Type" := PurchLine."Document Type";
                ToPurchLine."Document No." := PurchLine."Document No.";
                ToPurchLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToPurchLine.Description := TempExtTextLine.Text;
                ToPurchLine."Attached to Line No." := PurchLine."Line No.";
                OnBeforeToPurchLineInsert(ToPurchLine, PurchLine, TempExtTextLine, NextLineNo, LineSpacing);
                ToPurchLine.Insert();
            until TempExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
        LastInsertedPurchLine := ToPurchLine;
    end;

    local procedure DeleteSalesLines(var SalesLine: Record "Sales Line"): Boolean
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetRange("Attached to Line No.", SalesLine."Line No.");
        OnDeleteSalesLinesOnAfterSetFilters(SalesLine2, SalesLine);
        SalesLine2 := SalesLine;
        if SalesLine2.Find('>') then begin
            repeat
                SalesLine2.Delete(true);
            until SalesLine2.Next = 0;
            exit(true);
        end;
    end;

    local procedure DeleteReminderLines(var ReminderLine: Record "Reminder Line"): Boolean
    var
        ReminderLine2: Record "Reminder Line";
    begin
        ReminderLine2.SetRange("Reminder No.", ReminderLine."Reminder No.");
        ReminderLine2.SetRange("Attached to Line No.", ReminderLine."Line No.");
        ReminderLine2 := ReminderLine;
        if ReminderLine2.Find('>') then begin
            repeat
                ReminderLine2.Delete();
            until ReminderLine2.Next = 0;
            exit(true);
        end;
    end;

    local procedure DeleteFinChrgMemoLines(var FinChrgMemoLine: Record "Finance Charge Memo Line"): Boolean
    var
        FinChrgMemoLine2: Record "Finance Charge Memo Line";
    begin
        FinChrgMemoLine2.SetRange("Finance Charge Memo No.", FinChrgMemoLine."Finance Charge Memo No.");
        FinChrgMemoLine2.SetRange("Attached to Line No.", FinChrgMemoLine."Line No.");
        FinChrgMemoLine2 := FinChrgMemoLine;
        if FinChrgMemoLine2.Find('>') then begin
            repeat
                FinChrgMemoLine2.Delete();
            until FinChrgMemoLine2.Next = 0;
            exit(true);
        end;
    end;

    local procedure DeletePurchLines(var PurchLine: Record "Purchase Line"): Boolean
    var
        PurchLine2: Record "Purchase Line";
    begin
        PurchLine2.SetRange("Document Type", PurchLine."Document Type");
        PurchLine2.SetRange("Document No.", PurchLine."Document No.");
        PurchLine2.SetRange("Attached to Line No.", PurchLine."Line No.");
        OnDeletePurchLinesOnAfterSetFilters(PurchLine2, PurchLine);
        PurchLine2 := PurchLine;
        if PurchLine2.Find('>') then begin
            repeat
                PurchLine2.Delete(true);
            until PurchLine2.Next = 0;
            exit(true);
        end;
    end;

    procedure MakeUpdate(): Boolean
    begin
        exit(MakeUpdateRequired);
    end;

    local procedure ReadLines(var ExtTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]) Result: Boolean
    var
        ExtTextLine: Record "Extended Text Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReadLines(ExtTextHeader, DocDate, LanguageCode, IsHandled, Result);
        if IsHandled then
            exit(Result);

        ExtTextHeader.SetCurrentKey(
          "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
        ExtTextHeader.SetRange("Starting Date", 0D, DocDate);
        ExtTextHeader.SetFilter("Ending Date", '%1..|%2', DocDate, 0D);
        if LanguageCode = '' then begin
            ExtTextHeader.SetRange("Language Code", '');
            if not ExtTextHeader.FindSet then
                exit;
        end else begin
            ExtTextHeader.SetRange("Language Code", LanguageCode);
            if not ExtTextHeader.FindSet then begin
                ExtTextHeader.SetRange("All Language Codes", true);
                ExtTextHeader.SetRange("Language Code", '');
                if not ExtTextHeader.FindSet then
                    exit;
            end;
        end;
        TempExtTextLine.DeleteAll();
        repeat
            ExtTextLine.SetRange("Table Name", ExtTextHeader."Table Name");
            ExtTextLine.SetRange("No.", ExtTextHeader."No.");
            ExtTextLine.SetRange("Language Code", ExtTextHeader."Language Code");
            ExtTextLine.SetRange("Text No.", ExtTextHeader."Text No.");
            if ExtTextLine.FindSet then begin
                repeat
                    TempExtTextLine := ExtTextLine;
                    TempExtTextLine.Insert();
                until ExtTextLine.Next = 0;
                Result := true;
            end;
        until ExtTextHeader.Next = 0;

        OnAfterReadLines(TempExtTextLine, ExtTextHeader, LanguageCode);
    end;

    procedure ServCheckIfAnyExtText(var ServiceLine: Record "Service Line"; Unconditionally: Boolean): Boolean
    var
        ServHeader: Record "Service Header";
        ExtTextHeader: Record "Extended Text Header";
        ServCost: Record "Service Cost";
    begin
        MakeUpdateRequired := false;
        if IsDeleteAttachedLines(ServiceLine."Line No.", ServiceLine."No.", ServiceLine."Attached to Line No.") then
            MakeUpdateRequired := DeleteServiceLines(ServiceLine);

        AutoText := false;
        if Unconditionally then
            AutoText := true
        else
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    AutoText := true;
                ServiceLine.Type::Cost:
                    begin
                        if ServCost.Get(ServiceLine."No.") then
                            if GLAcc.Get(ServCost."Account No.") then
                                AutoText := GLAcc."Automatic Ext. Texts";
                    end;
                ServiceLine.Type::Item:
                    begin
                        if Item.Get(ServiceLine."No.") then
                            AutoText := Item."Automatic Ext. Texts";
                    end;
                ServiceLine.Type::Resource:
                    begin
                        if Res.Get(ServiceLine."No.") then
                            AutoText := Res."Automatic Ext. Texts";
                    end;
                ServiceLine.Type::"G/L Account":
                    begin
                        if GLAcc.Get(ServiceLine."No.") then
                            AutoText := GLAcc."Automatic Ext. Texts";
                    end;
            end;

        OnServCheckIfAnyExtTextOnBeforeSetFilters(ServiceLine, AutoText);

        if AutoText then begin
            case ServiceLine.Type of
                ServiceLine.Type::" ":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"Standard Text");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Item:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Item);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Resource:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::Resource);
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
                ServiceLine.Type::Cost:
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ServCost.Get(ServiceLine."No.");
                        ExtTextHeader.SetRange("No.", ServCost."Account No.");
                    end;
                ServiceLine.Type::"G/L Account":
                    begin
                        ExtTextHeader.SetRange("Table Name", ExtTextHeader."Table Name"::"G/L Account");
                        ExtTextHeader.SetRange("No.", ServiceLine."No.");
                    end;
            end;

            case ServiceLine."Document Type" of
                ServiceLine."Document Type"::Quote:
                    ExtTextHeader.SetRange("Service Quote", true);
                ServiceLine."Document Type"::Order:
                    ExtTextHeader.SetRange("Service Order", true);
                ServiceLine."Document Type"::Invoice:
                    ExtTextHeader.SetRange("Service Invoice", true);
                ServiceLine."Document Type"::"Credit Memo":
                    ExtTextHeader.SetRange("Service Credit Memo", true);
            end;
            ServHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
            OnServCheckIfAnyExtTextAutoText(ExtTextHeader, ServHeader, ServiceLine, Unconditionally, MakeUpdateRequired);
            exit(ReadLines(ExtTextHeader, ServHeader."Order Date", ServHeader."Language Code"));
        end;
    end;

    local procedure DeleteServiceLines(var ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2.SetRange("Attached to Line No.", ServiceLine."Line No.");
        ServiceLine2 := ServiceLine;
        if ServiceLine2.Find('>') then begin
            repeat
                ServiceLine2.Delete();
            until ServiceLine2.Next = 0;
            exit(true);
        end;
    end;

    procedure GetTempExtTextLine(var ToTempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
        ToTempExtendedTextLine.Copy(TempExtTextLine, true);
    end;

    procedure InsertServExtText(var ServiceLine: Record "Service Line")
    var
        ToServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        OnBeforeInsertServExtText(ServiceLine, TempExtTextLine, IsHandled, MakeUpdateRequired);
        if IsHandled then
            exit;

        ToServiceLine.Reset();
        ToServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ToServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ToServiceLine := ServiceLine;
        if ToServiceLine.Find('>') then begin
            LineSpacing :=
              (ToServiceLine."Line No." - ServiceLine."Line No.") div
              (1 + TempExtTextLine.Count);
            if LineSpacing = 0 then
                Error(Text000);
        end else
            LineSpacing := 10000;

        NextLineNo := ServiceLine."Line No." + LineSpacing;

        TempExtTextLine.Reset();
        if TempExtTextLine.Find('-') then begin
            repeat
                ToServiceLine.Init();
                ToServiceLine."Document Type" := ServiceLine."Document Type";
                ToServiceLine."Document No." := ServiceLine."Document No.";
                ToServiceLine."Service Item Line No." := ServiceLine."Service Item Line No.";
                ToServiceLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + LineSpacing;
                ToServiceLine.Description := TempExtTextLine.Text;
                ToServiceLine."Attached to Line No." := ServiceLine."Line No.";
                ToServiceLine."Service Item No." := ServiceLine."Service Item No.";
                OnBeforeToServiceLineInsert(ServiceLine, ToServiceLine, TempExtTextLine, NextLineNo, LineSpacing);
                ToServiceLine.Insert(true);
            until TempExtTextLine.Next = 0;
            MakeUpdateRequired := true;
        end;
        TempExtTextLine.DeleteAll();
    end;

    local procedure IsDeleteAttachedLines(LineNo: Integer; No: Code[20]; AttachedToLineNo: Integer): Boolean
    begin
        exit((LineNo <> 0) and (AttachedToLineNo = 0) and (No <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReadLines(var TempExtendedTextLine: Record "Extended Text Line" temporary; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocDate: Date; LanguageCode: Code[10]; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToSalesLineInsert(var ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToServiceLineInsert(var ToServLine: Record "Service Line"; ServLine: Record "Service Line"; TempExtTextLine: Record "Extended Text Line" temporary; var NextLineNo: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToReminderLineInsert(var ToReminderLine: Record "Reminder Line"; ReminderLine: Record "Reminder Line"; TempExtTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePurchLinesOnAfterSetFilters(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesOnAfterSetFilters(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinChrgMemoCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtGetAnyExtTextAfterReadLines(var ExtendedTextHeader: Record "Extended Text Header"; var TempExtendedTextLine: Record "Extended Text Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtGetAnyExtTextBeforeReadLines(var ExtendedTextHeader: Record "Extended Text Header"; DocumentDate: Date; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReminderCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextAutoText(var ExtendedTextHeader: Record "Extended Text Header"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; Unconditionally: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesExtText(var SalesLine: Record "Sales Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReminderExtText(var ReminderLine: Record "Reminder Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFinChrgMemoExtText(var FinChrgMemoLine: Record "Finance Charge Memo Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchExtText(var PurchLine: Record "Purchase Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServExtText(var ServiceLine: Record "Service Line"; var TempExtTextLine: Record "Extended Text Line" temporary; var IsHandled: Boolean; var MakeUpdateRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchCheckIfAnyExtTextOnBeforeSetFilters(var PurchaseLine: Record "Purchase Line"; var AutoText: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesCheckIfAnyExtTextOnBeforeSetFilters(var SalesLine: Record "Sales Line"; var AutoText: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServCheckIfAnyExtTextOnBeforeSetFilters(var ServiceLine: Record "Service Line"; var AutoText: Boolean)
    begin
    end;
}


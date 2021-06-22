codeunit 7111 "Insert Analysis Line"
{

    trigger OnRun()
    begin
    end;

    procedure InsertItems(var AnalysisLine: Record "Analysis Line")
    var
        Item: Record Item;
        ItemList: Page "Item List";
        ItemCount: Integer;
        AnalysisLineNo: Integer;
    begin
        ItemList.LookupMode(true);
        if ItemList.RunModal = ACTION::LookupOK then begin
            ItemList.SetSelection(Item);
            ItemCount := Item.Count();
            if ItemCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, ItemCount);

                if Item.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Item.Description, Item."No.", AnalysisLine.Type::Item, false, 0);
                    until Item.Next = 0;
            end;
        end;
    end;

    procedure InsertCust(var AnalysisLine: Record "Analysis Line")
    var
        Cust: Record Customer;
        CustList: Page "Customer List";
        CustCount: Integer;
        AnalysisLineNo: Integer;
    begin
        CustList.LookupMode(true);
        if CustList.RunModal = ACTION::LookupOK then begin
            CustList.SetSelection(Cust);
            CustCount := Cust.Count();
            if CustCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, CustCount);

                if Cust.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Cust.Name, Cust."No.", AnalysisLine.Type::Customer, false, 0);
                    until Cust.Next = 0;
            end;
        end;
    end;

    procedure InsertVend(var AnalysisLine: Record "Analysis Line")
    var
        Vend: Record Vendor;
        VendList: Page "Vendor List";
        VendCount: Integer;
        AnalysisLineNo: Integer;
    begin
        VendList.LookupMode(true);
        if VendList.RunModal = ACTION::LookupOK then begin
            VendList.SetSelection(Vend);
            VendCount := Vend.Count();
            if VendCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, VendCount);

                if Vend.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          Vend.Name, Vend."No.", AnalysisLine.Type::Vendor, false, 0);
                    until Vend.Next = 0;
            end;
        end;
    end;

    procedure InsertItemGrDim(var AnalysisLine: Record "Analysis Line")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Item Group Dimension Code");
        InsertGroup(
          AnalysisLine,
          InventorySetup."Item Group Dimension Code",
          AnalysisLine.Type::"Item Group");
    end;

    procedure InsertCustGrDim(var AnalysisLine: Record "Analysis Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Customer Group Dimension Code");
        InsertGroup(
          AnalysisLine,
          SalesSetup."Customer Group Dimension Code",
          AnalysisLine.Type::"Customer Group");
    end;

    procedure InsertSalespersonPurchaser(var AnalysisLine: Record "Analysis Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Salesperson Dimension Code");
        InsertGroup(
          AnalysisLine,
          SalesSetup."Salesperson Dimension Code",
          AnalysisLine.Type::"Sales/Purchase person");
    end;

    local procedure InsertGroup(var AnalysisLine: Record "Analysis Line"; GroupDimCode: Code[20]; TotalingType: Integer)
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
        DimValCount: Integer;
        AnalysisLineNo: Integer;
    begin
        DimVal.FilterGroup := 2;
        DimVal.SetRange("Dimension Code", GroupDimCode);
        DimVal.FilterGroup := 0;
        DimValList.SetTableView(DimVal);
        DimValList.LookupMode(true);
        if DimValList.RunModal = ACTION::LookupOK then begin
            DimValList.SetSelection(DimVal);
            DimValCount := DimVal.Count();
            if DimValCount > 0 then begin
                MoveAnalysisLines(AnalysisLine, AnalysisLineNo, DimValCount);

                if DimVal.Find('-') then
                    repeat
                        InsertAnalysisLine(
                          AnalysisLine, AnalysisLineNo,
                          DimVal.Name, DimVal.Code, TotalingType,
                          DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard,
                          DimVal.Indentation);
                    until DimVal.Next = 0;
            end;
        end;
    end;

    local procedure MoveAnalysisLines(var AnalysisLine: Record "Analysis Line"; var AnalysisLineNo: Integer; NewLineCount: Integer)
    var
        i: Integer;
    begin
        with AnalysisLine do begin
            AnalysisLineNo := "Line No.";
            SetRange("Analysis Area", "Analysis Area");
            SetRange("Analysis Line Template Name", "Analysis Line Template Name");
            if Find('+') then
                repeat
                    i := "Line No.";
                    if i >= AnalysisLineNo then begin
                        Delete;
                        "Line No." := i + 10000 * NewLineCount;
                        Insert(true);
                    end;
                until (i <= AnalysisLineNo) or (Next(-1) = 0);

            if AnalysisLineNo = 0 then
                AnalysisLineNo := 10000;
        end;
    end;

    local procedure InsertAnalysisLine(var AnalysisLine: Record "Analysis Line"; var AnalysisLineNo: Integer; Text: Text[100]; No: Code[20]; Type2: Integer; Bold2: Boolean; Indent: Integer)
    begin
        with AnalysisLine do begin
            Init;
            "Line No." := AnalysisLineNo;
            AnalysisLineNo := AnalysisLineNo + 10000;
            Description := Text;
            Range := No;
            "Row Ref. No." := CopyStr(No, 1, MaxStrLen("Row Ref. No."));
            Type := Type2;
            Bold := Bold2;
            Indentation := Indent;
            Insert(true);
        end;
    end;
}


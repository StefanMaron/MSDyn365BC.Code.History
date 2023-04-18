codeunit 550 "VAT Rate Change Conversion"
{
    Permissions = TableData "VAT Rate Change Log Entry" = i;

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(IsHandled);
        if IsHandled then
            exit;

        if not VATRateChangeSetup.Get() then begin
            VATRateChangeSetup.Init();
            VATRateChangeSetup.Insert();
        end;

        Convert();
    end;

    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
        UOMMgt: Codeunit "Unit of Measure Management";
        ProgressWindow: Dialog;
        Text0001: Label 'Progressing Table #1#####################################  ';
        Text0002: Label 'Progressing Record #2############ of #3####################  ';
        Text0004: Label 'Order line %1 has a drop shipment purchasing code. Update the order manually.';
        Text0005: Label 'Order line %1 has a special order purchasing code. Update the order manually.';
        Text0006: Label 'The order has a partially shipped line with link to a WHSE document. Update the order manually.';
        Text0007: Label 'There is nothing to convert. The outstanding quantity is zero.';
        Text0008: Label 'There must be an entry in the %1 table for the combination of VAT business posting group %2 and VAT product posting group %3.';
        Text0009: Label 'Conversion cannot be performed before %1 is set to true.';
        Text0010: Label 'The line has been shipped.';
        Text0011: Label 'Documents that have posted prepayment must be converted manually.';
        Text0012: Label 'This line %1 has been split into two lines. The outstanding quantity will be on the new line.';
        Text0013: Label 'This line %1 has been added. It contains the outstanding quantity from line %2.';
        Text0014: Label 'The order line %1 of type %2 have been partial Shipped/Invoiced . Update the order manually.';
        Text0015: Label 'A defined conversion does not exist. Define the conversion.';
        Text0016: Label 'Defined tables for conversion do not exist.';
        Text0017: Label 'This line %1 will be split into two lines. The outstanding quantity will be on the new line.';
        Text0018: Label 'This document is linked to an assembly order. You must convert the document manually.';

    local procedure Convert()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        TempGenProductPostingGroup: Record "Gen. Product Posting Group" temporary;
    begin
        OnBeforeConvert(VATRateChangeSetup);

        VATRateChangeSetup.TestField("VAT Rate Change Tool Completed", false);
        if VATRateChangeConversion.IsEmpty() then
            Error(Text0015);
        if not AreTablesSelected() then
            Error(Text0016);
        TestVATPostingSetup();
        ProgressWindow.Open(Text0001 + Text0002);
        OnConvertOnBeforeStartConvert(VATRateChangeSetup);
        with VATRateChangeSetup do begin
            ProgressWindow.Update();
            UpdateTable(
              DATABASE::"Gen. Product Posting Group",
              ConvertVATProdPostGrp("Update Gen. Prod. Post. Groups"), ConvertGenProdPostGrp("Update Gen. Prod. Post. Groups"));
            TempGenProductPostingGroup.DeleteAll();
            if GenProductPostingGroup.Find('-') then
                repeat
                    TempGenProductPostingGroup := GenProductPostingGroup;
                    TempGenProductPostingGroup.Insert();
                    GenProductPostingGroup."Auto Insert Default" := false;
                    GenProductPostingGroup.Modify();
                until GenProductPostingGroup.Next() = 0;
            UpdateItem();
            UpdateResource();
            UpdateGLAccount();
            UpdateServPriceAdjDetail();
            UpdatePurchase();
            UpdateSales();
            UpdateService();
            UpdateTables();

            OnBeforeFinishConvert(VATRateChangeSetup, ProgressWindow);

            GenProductPostingGroup.DeleteAll();
            if TempGenProductPostingGroup.Find('-') then
                repeat
                    GenProductPostingGroup := TempGenProductPostingGroup;
                    GenProductPostingGroup.Insert();
                    TempGenProductPostingGroup.Delete();
                until TempGenProductPostingGroup.Next() = 0;
        end;

        ProgressWindow.Close();

        if VATRateChangeSetup."Perform Conversion" then begin
            VATRateChangeSetup."VAT Rate Change Tool Completed" := true;
            VATRateChangeSetup.Modify();
            VATRateChangeConversion.Reset();
            if VATRateChangeConversion.FindSet(true) then
                repeat
                    VATRateChangeConversion."Converted Date" := WorkDate();
                    VATRateChangeConversion.Modify();
                until VATRateChangeConversion.Next() = 0;
        end;

        OnAfterConvert(VATRateChangeSetup);
    end;

    local procedure UpdateTables()
    begin
        with VATRateChangeSetup do begin
            UpdateTable(
                Database::"Item Templ.",
                ConvertVATProdPostGrp("Update Item Templates"), ConvertGenProdPostGrp("Update Item Templates"));
            UpdateTable(
              DATABASE::"Item Charge",
              ConvertVATProdPostGrp("Update Item Charges"), ConvertGenProdPostGrp("Update Item Charges"));
            UpdateTable(
              DATABASE::"Gen. Journal Line",
              ConvertVATProdPostGrp("Update Gen. Journal Lines"), ConvertGenProdPostGrp("Update Gen. Journal Lines"));
            UpdateTable(
              DATABASE::"Gen. Jnl. Allocation",
              ConvertVATProdPostGrp("Update Gen. Journal Allocation"), ConvertGenProdPostGrp("Update Gen. Journal Allocation"));
            UpdateTable(
              DATABASE::"Standard General Journal Line",
              ConvertVATProdPostGrp("Update Std. Gen. Jnl. Lines"), ConvertGenProdPostGrp("Update Std. Gen. Jnl. Lines"));
            UpdateTable(
              DATABASE::"Res. Journal Line",
              ConvertVATProdPostGrp("Update Res. Journal Lines"), ConvertGenProdPostGrp("Update Res. Journal Lines"));
            UpdateTable(
              DATABASE::"Job Journal Line",
              ConvertVATProdPostGrp("Update Job Journal Lines"), ConvertGenProdPostGrp("Update Job Journal Lines"));
            UpdateTable(
              DATABASE::"Requisition Line",
              ConvertVATProdPostGrp("Update Requisition Lines"), ConvertGenProdPostGrp("Update Requisition Lines"));
            UpdateTable(
              DATABASE::"Standard Item Journal Line",
              ConvertVATProdPostGrp("Update Std. Item Jnl. Lines"), ConvertGenProdPostGrp("Update Std. Item Jnl. Lines"));
            UpdateTable(
              DATABASE::"Production Order",
              ConvertVATProdPostGrp("Update Production Orders"), ConvertGenProdPostGrp("Update Production Orders"));
            UpdateTable(
              DATABASE::"Work Center",
              ConvertVATProdPostGrp("Update Work Centers"), ConvertGenProdPostGrp("Update Work Centers"));
            UpdateTable(
              DATABASE::"Machine Center",
              ConvertVATProdPostGrp("Update Machine Centers"), ConvertGenProdPostGrp("Update Machine Centers"));
            UpdateTable(
              DATABASE::"Reminder Line",
              ConvertVATProdPostGrp("Update Reminders"), ConvertGenProdPostGrp("Update Reminders"));
            UpdateTable(
              DATABASE::"Finance Charge Memo Line",
              ConvertVATProdPostGrp("Update Finance Charge Memos"), ConvertGenProdPostGrp("Update Finance Charge Memos"));
        end;

        OnAfterUpdateTables(VATRateChangeSetup);
    end;

    local procedure TestVATPostingSetup()
    var
        VATPostingSetupOld: Record "VAT Posting Setup";
        VATPostingSetupNew: Record "VAT Posting Setup";
        VATRateChangeConversion: Record "VAT Rate Change Conversion";
    begin
        VATRateChangeConversion.SetRange(Type, VATRateChangeConversion.Type::"VAT Prod. Posting Group");
        if VATRateChangeConversion.FindSet() then
            repeat
                VATPostingSetupOld.SetRange("VAT Prod. Posting Group", VATRateChangeConversion."From Code");
                OnTestVATPostingSetupOnAfterVATPostingSetupOldSetFilters(VATPostingSetupOld, VATRateChangeSetup);
                if VATPostingSetupOld.FindSet() then
                    repeat
                        if not VATPostingSetupNew.Get(VATPostingSetupOld."VAT Bus. Posting Group", VATRateChangeConversion."To Code") then
                            Error(
                              Text0008,
                              VATPostingSetupNew.TableCaption(),
                              VATPostingSetupOld."VAT Bus. Posting Group",
                              VATRateChangeConversion."To Code");
                        if VATPostingSetupOld."VAT Identifier" <> '' then
                            VATPostingSetupNew.TestField("VAT Identifier")
                    until VATPostingSetupOld.Next() = 0;
            until VATRateChangeConversion.Next() = 0;
    end;

    local procedure UpdateItem()
    var
        Item: Record Item;
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, Item.TableCaption());

        IsHandled := false;
        OnBeforeUpdateItem(Item, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        with VATRateChangeSetup do
            if "Item Filter" = '' then
                UpdateTable(DATABASE::Item, ConvertVATProdPostGrp("Update Items"), ConvertGenProdPostGrp("Update Items"))
            else begin
                Item.SetFilter("No.", "Item Filter");
                if Item.Find('-') then
                    repeat
                        RecRef.GetTable(Item);
                        UpdateRec(RecRef, ConvertVATProdPostGrp("Update Items"), ConvertGenProdPostGrp("Update Items"));
                    until Item.Next() = 0;
            end;
    end;

    local procedure UpdateGLAccount()
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, GLAccount.TableCaption());

        IsHandled := false;
        OnBeforeUpdateGLAccount(GLAccount, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        with VATRateChangeSetup do
            if "Account Filter" = '' then
                UpdateTable(DATABASE::"G/L Account", ConvertVATProdPostGrp("Update G/L Accounts"), ConvertGenProdPostGrp("Update G/L Accounts"))
            else begin
                GLAccount.SetFilter("No.", "Account Filter");
                if GLAccount.Find('-') then
                    repeat
                        RecRef.GetTable(GLAccount);
                        UpdateRec(RecRef, ConvertVATProdPostGrp("Update G/L Accounts"), ConvertGenProdPostGrp("Update G/L Accounts"));
                    until GLAccount.Next() = 0;
            end;
    end;

    local procedure UpdateResource()
    var
        Resource: Record Resource;
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResource(Resource, VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        with VATRateChangeSetup do
            if "Resource Filter" = '' then
                UpdateTable(DATABASE::Resource, ConvertVATProdPostGrp("Update Resources"), ConvertGenProdPostGrp("Update Resources"))
            else begin
                Resource.SetFilter("No.", "Resource Filter");
                if Resource.Find('-') then
                    repeat
                        RecRef.GetTable(Resource);
                        UpdateRec(RecRef, ConvertVATProdPostGrp("Update Resources"), ConvertGenProdPostGrp("Update Resources"));
                    until Resource.Next() = 0;
            end;
    end;

    procedure ConvertVATProdPostGrp(UpdateOption: Option): Boolean
    var
        DummyVATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        if UpdateOption in [DummyVATRateChangeSetup."Update Items"::"VAT Prod. Posting Group",
                            DummyVATRateChangeSetup."Update Items"::Both]
        then
            exit(true);
        exit(false);
    end;

    procedure ConvertGenProdPostGrp(UpdateOption: Option): Boolean
    var
        DummyVATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        if UpdateOption in [DummyVATRateChangeSetup."Update Items"::"Gen. Prod. Posting Group",
                            DummyVATRateChangeSetup."Update Items"::Both]
        then
            exit(true);
        exit(false);
    end;

    procedure UpdateTable(TableID: Integer; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    var
        RecRef: RecordRef;
        I: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTable(TableID, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup, IsHandled);
        if IsHandled then
            exit;

        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;
        RecRef.Open(TableID);
        ProgressWindow.Update(1, Format(RecRef.Caption));
        I := 0;
        ProgressWindow.Update(3, RecRef.Count);
        if RecRef.Find('-') then
            repeat
                I := I + 1;
                ProgressWindow.Update(2, I);
                UpdateRec(RecRef, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
            until RecRef.Next() = 0;
    end;

    procedure UpdateRec(var RecRef: RecordRef; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    var
        "Field": Record "Field";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        FldRef: FieldRef;
        GenProdPostingGroupConverted: Boolean;
        VATProdPostingGroupConverted: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRec(RecRef, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup, IsHandled);
        if IsHandled then
            exit;

        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(RelationTableNo, DATABASE::"Gen. Product Posting Group");
        Field.SetRange(Type, Field.Type::Code);
        if Field.Find('+') then
            repeat
                FldRef := RecRef.Field(Field."No.");
                GenProdPostingGroupConverted := false;
                if ConvertGenProdPostingGroup then
                    if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"Gen. Prod. Posting Group", Format(FldRef.Value())) then begin
                        VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := FldRef.Value;
                        IsHandled := false;
                        OnUpdateRecOnBeforeValidateGenProdPostingGroup(RecRef, FldRef, VATRateChangeConversion, IsHandled);
                        if not IsHandled then
                            FldRef.Validate(VATRateChangeConversion."To Code");
                        VATRateChangeLogEntry."New Gen. Prod. Posting Group" := FldRef.Value;
                        GenProdPostingGroupConverted := true;
                    end;
                if not GenProdPostingGroupConverted then begin
                    VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := FldRef.Value;
                    VATRateChangeLogEntry."New Gen. Prod. Posting Group" := FldRef.Value;
                end;
            until Field.Next(-1) = 0;

        Field.SetRange(RelationTableNo, DATABASE::"VAT Product Posting Group");
        if Field.Find('+') then
            repeat
                FldRef := RecRef.Field(Field."No.");
                VATProdPostingGroupConverted := false;
                if ConvertVATProdPostingGroup then
                    if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"VAT Prod. Posting Group", Format(FldRef.Value())) then begin
                        VATRateChangeLogEntry."Old VAT Prod. Posting Group" := FldRef.Value;
                        FldRef.Validate(VATRateChangeConversion."To Code");
                        VATRateChangeLogEntry."New VAT Prod. Posting Group" := FldRef.Value;
                        VATProdPostingGroupConverted := true;
                    end;
                if not VATProdPostingGroupConverted then begin
                    VATRateChangeLogEntry."Old VAT Prod. Posting Group" := FldRef.Value;
                    VATRateChangeLogEntry."New VAT Prod. Posting Group" := FldRef.Value;
                end;
            until Field.Next(-1) = 0;

        VATRateChangeSetup.Get();
        if VATRateChangeSetup."Perform Conversion" then begin
            OnUpdateRecOnBeforeRecRefModify(RecRef, GenProdPostingGroupConverted, VATProdPostingGroupConverted);
            RecRef.Modify();
            OnUpdateRecOnAfterRecRefModify(RecRef, GenProdPostingGroupConverted, VATProdPostingGroupConverted);
            VATRateChangeLogEntry.Converted := true;
        end;
        if (VATRateChangeLogEntry."New Gen. Prod. Posting Group" <> VATRateChangeLogEntry."Old Gen. Prod. Posting Group") or
           (VATRateChangeLogEntry."New VAT Prod. Posting Group" <> VATRateChangeLogEntry."Old VAT Prod. Posting Group")
        then
            WriteLogEntry(VATRateChangeLogEntry);
    end;

    procedure WriteLogEntry(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry")
    begin
        with VATRateChangeLogEntry do begin
            if Converted then
                "Converted Date" := WorkDate()
            else
                if Description = '' then
                    Description := StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
            Insert();
        end;
    end;

    local procedure UpdateSales()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineOld: Record "Sales Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        SalesHeaderStatusChanged: Boolean;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
        IsModified: Boolean;
    begin
        ProgressWindow.Update(1, SalesHeader.TableCaption());
        ConvertVATProdPostingGroup := ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents");
        ConvertGenProdPostingGroup := ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdateSales(VATRateChangeSetup, IsHandled, SalesHeader);
        if IsHandled then
            exit;

        SalesHeader.SetFilter(
          "Document Type", '%1..%2|%3', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::"Blanket Order");
        OnUpdateSalesOnAfterSalesHeaderSetFilters(VATRateChangeSetup, SalesHeader);
        if SalesHeader.Find('-') then
            repeat
                SalesHeaderStatusChanged := false;
                if CanUpdateSales(SalesHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup) then begin
                    if VATRateChangeSetup."Ignore Status on Sales Docs." then
                        if SalesHeader.Status <> SalesHeader.Status::Open then begin
                            SalesHeader2 := SalesHeader;
                            SalesHeader.Status := SalesHeader.Status::Open;
                            SalesHeader.Modify();
                            SalesHeaderStatusChanged := true;
                            OnUpdateSalesOnAfterOpenSalesHeader(SalesHeader);
                        end;
                    if SalesHeader.Status = SalesHeader.Status::Open then begin
                        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader."No.");
                        OnUpdateSalesOnAfterSalesLineSetFilters(VATRateChangeSetup, SalesHeader, SalesLine);
                        if SalesLine.FindSet() then
                            repeat
                                if LineInScope(
                                     SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup,
                                     ConvertVATProdPostingGroup)
                                then
                                    if (SalesLine."Shipment No." = '') and (SalesLine."Return Receipt No." = '') and
                                       IncludeSalesLine(SalesLine.Type, SalesLine."No.")
                                    then
                                        if SalesLine.Quantity = SalesLine."Outstanding Quantity" then begin
                                            OnUpdateSalesOnBeforeChangeSalesLine(SalesLine);

                                            RecRef.GetTable(SalesLine);
                                            if SalesHeader."Prices Including VAT" then
                                                SalesLineOld := SalesLine;

                                            UpdateRec(
                                              RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents"),
                                              ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents"));

                                            SalesLine.Find();
                                            IsModified := false;
                                            if SalesHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                                               (SalesLine."VAT %" <> SalesLineOld."VAT %") and
                                               UpdateUnitPriceInclVAT(SalesLine.Type)
                                            then begin
                                                RoundingPrecision := GetRoundingPrecision(SalesHeader."Currency Code");
                                                SalesLine.Validate(
                                                  "Unit Price",
                                                  Round(
                                                    SalesLineOld."Unit Price" * (100 + SalesLine."VAT %") / (100 + SalesLineOld."VAT %"), RoundingPrecision));
                                                IsModified := true;
                                            end;
                                            if SalesLine."Prepayment %" <> 0 then begin
                                                SalesLine.UpdatePrepmtSetupFields();
                                                IsModified := true;
                                            end;
                                            OnUpdateSalesOnBeforeModifySalesLine(SalesLine, IsModified);
                                            if IsModified then
                                                SalesLine.Modify(true);
                                            OnUpdateSalesOnAfterModifySalesLine(SalesLine, IsModified, VATRateChangeSetup, SalesHeader, SalesLineOld);
                                        end else
                                            if VATRateChangeSetup."Perform Conversion" and (SalesLine."Outstanding Quantity" <> 0) then begin
                                                NewVATProdPotingGroup := SalesLine."VAT Prod. Posting Group";
                                                NewGenProdPostingGroup := SalesLine."Gen. Prod. Posting Group";
                                                if VATRateChangeConversion.Get(
                                                     VATRateChangeConversion.Type::"VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group")
                                                then
                                                    NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                                if VATRateChangeConversion.Get(
                                                     VATRateChangeConversion.Type::"Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group")
                                                then
                                                    NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                                AddNewSalesLine(SalesLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                                            end else begin
                                                RecRef.GetTable(SalesLine);
                                                InitVATRateChangeLogEntry(
                                                  VATRateChangeLogEntry, RecRef, SalesLine."Outstanding Quantity", SalesLine."Line No.");
                                                VATRateChangeLogEntry.UpdateGroups(
                                                  SalesLine."Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group",
                                                  SalesLine."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
                                                WriteLogEntry(VATRateChangeLogEntry);
                                            end;
                            until SalesLine.Next() = 0;
                        OnUpdateSalesOnAfterUpdateSalesLines(VATRateChangeSetup, SalesHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
                    end;
                    if SalesHeaderStatusChanged then begin
                        SalesHeader.Status := SalesHeader2.Status;
                        SalesHeader.Modify();
                        OnUpdateSalesOnAfterResetSalesHeaderStatus(SalesHeader);
                    end;
                end;
            until SalesHeader.Next() = 0;
    end;

    local procedure CanUpdateSales(SalesHeader: Record "Sales Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean): Boolean
    var
        SalesLine: Record "Sales Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            OnCanUpdateSalesOnAfterSalesLineSetFilters(SalesLine);
            if FindSet() then
                repeat
                    DescriptionTxt := '';
                    if LineInScope("Gen. Prod. Posting Group", "VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                        if "Drop Shipment" and ("Purchase Order No." <> '') then
                            DescriptionTxt := StrSubstNo(Text0004, "Line No.");
                        if "Special Order" and ("Special Order Purchase No." <> '') then
                            DescriptionTxt := StrSubstNo(Text0005, "Line No.");
                        CheckSalesLinePartlyShipped(SalesLine, DescriptionTxt);
                        if ("Outstanding Quantity" <> Quantity) and (Type = Type::"Charge (Item)") then
                            DescriptionTxt := StrSubstNo(Text0014, "Line No.", Type::"Charge (Item)");
                        if "Prepmt. Amount Inv. Incl. VAT" <> 0 then
                            DescriptionTxt := Text0011;
                        if "Qty. to Assemble to Order" <> 0 then
                            DescriptionTxt := Text0018;
                        OnCanUpdateSalesOnAfterLoopIteration(DescriptionTxt, SalesLine);
                    end;
                until (Next() = 0) or (DescriptionTxt <> '');
        end;
        if DescriptionTxt = '' then
            exit(true);

        RecRef.GetTable(SalesHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure CheckSalesLinePartlyShipped(var SalesLine: Record "Sales Line"; var DescriptionTxt: Text[250])
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLinePartlyShipped(SalesLine, DescriptionTxt, IsHandled);
        if IsHandled then
            exit;

        with SalesLine do
            if ("Outstanding Quantity" <> Quantity) and
               WhseValidateSourceLine.WhseLinesExist(DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
            then
                DescriptionTxt := Text0006;
    end;

    procedure AddNewSalesLine(SalesLine: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewSalesLine: Record "Sales Line";
        OldSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        OldItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        NewItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        RoundingPrecision: Decimal;
    begin
        if not GetNextSalesLineNo(SalesLine, NewLineNo) then
            exit;
        with NewSalesLine do begin
            InitNewSalesLineFromSalesLine(NewSalesLine, SalesLine, NewLineNo);
            if (GenProdPostingGroup <> '') and ConvertGenProdPostGrp(VATRateChangeSetup."Update Sales Documents") then
                Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            if (VATProdPostingGroup <> '') and ConvertVATProdPostGrp(VATRateChangeSetup."Update Sales Documents") then
                Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            Validate(Quantity, SalesLine."Outstanding Quantity");
            Validate("Qty. to Ship", SalesLine."Qty. to Ship");
            Validate("Return Qty. to Receive", SalesLine."Return Qty. to Receive");
            if Abs(SalesLine."Qty. to Invoice") > (Abs(SalesLine."Quantity Shipped") - Abs(SalesLine."Quantity Invoiced")) then
                Validate(
                  "Qty. to Invoice", SalesLine."Qty. to Invoice" - (SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced"))
            else
                Validate("Qty. to Invoice", 0);
            SalesHeader.Get("Document Type", "Document No.");
            RoundingPrecision := GetRoundingPrecision(SalesHeader."Currency Code");
            if SalesHeader."Prices Including VAT" then
                Validate("Unit Price", Round(SalesLine."Unit Price" * (100 + "VAT %") / (100 + SalesLine."VAT %"), RoundingPrecision))
            else
                Validate("Unit Price", SalesLine."Unit Price");
            Validate("Line Discount %", SalesLine."Line Discount %");
            Insert();
            OnAddNewSalesLineOnAfterInsertNewLine(Salesline, NewSalesline);

            RecRef.GetTable(SalesLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              SalesLine."Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group",
              SalesLine."VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(SalesLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            RecRef.GetTable(NewSalesLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              SalesLine."Gen. Prod. Posting Group", "Gen. Prod. Posting Group",
              SalesLine."VAT Prod. Posting Group", "VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format("Line No."), Format(SalesLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);
        end;

        UpdateSalesBlanketOrder(NewSalesLine, SalesLine."Line No.");
        UpdateAttachedToLineNoSales(NewSalesLine, SalesLine."Line No.");

        OldReservationEntry.Reset();
        OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        OldReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        OldReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        OldReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        OldReservationEntry.SetRange("Source Subtype", SalesLine."Document Type");
        if OldReservationEntry.FindSet() then
            repeat
                NewReservationEntry := OldReservationEntry;
                NewReservationEntry."Source Ref. No." := NewLineNo;
                NewReservationEntry.Modify();
            until OldReservationEntry.Next() = 0;

        case SalesLine.Type of
            SalesLine.Type::Item:
                begin
                    OldItemChargeAssignmentSales.Reset();
                    OldItemChargeAssignmentSales.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    OldItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", SalesLine."Document Type");
                    OldItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SalesLine."Document No.");
                    OldItemChargeAssignmentSales.SetRange("Applies-to Doc. Line No.", SalesLine."Line No.");
                    if OldItemChargeAssignmentSales.Find('-') then
                        repeat
                            QtyRemainder := OldItemChargeAssignmentSales."Qty. to Assign";
                            AmountRemainder := OldItemChargeAssignmentSales."Amount to Assign";
                            NewItemChargeAssignmentSales := OldItemChargeAssignmentSales;
                            NewItemChargeAssignmentSales."Line No." := GetNextItemChrgAssSaleLineNo(OldItemChargeAssignmentSales);
                            NewItemChargeAssignmentSales."Applies-to Doc. Line No." := NewLineNo;
                            NewItemChargeAssignmentSales."Qty. to Assign" :=
                              Round(QtyRemainder / SalesLine.Quantity * SalesLine."Outstanding Quantity", UOMMgt.QtyRndPrecision());
                            if SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced" = 0 then
                                NewItemChargeAssignmentSales."Qty. to Assign" := QtyRemainder;
                            NewItemChargeAssignmentSales."Amount to Assign" :=
                              Round(NewItemChargeAssignmentSales."Qty. to Assign" * NewItemChargeAssignmentSales."Unit Cost", RoundingPrecision);
                            NewItemChargeAssignmentSales.Insert();
                            QtyRemainder := QtyRemainder - NewItemChargeAssignmentSales."Qty. to Assign";
                            AmountRemainder := AmountRemainder - NewItemChargeAssignmentSales."Amount to Assign";
                            OldItemChargeAssignmentSales."Qty. to Assign" := QtyRemainder;
                            OldItemChargeAssignmentSales."Amount to Assign" := AmountRemainder;
                            OldItemChargeAssignmentSales.Modify();
                        until OldItemChargeAssignmentSales.Next() = 0;
                end;
        end;

        OldSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        OldSalesLine.Validate(Quantity, SalesLine."Quantity Shipped");

        OldSalesLine.Validate("Unit Price", SalesLine."Unit Price");
        OldSalesLine.Validate("Line Discount %", SalesLine."Line Discount %");
        OldSalesLine.Validate("Qty. to Ship", 0);
        OldSalesLine.Validate("Return Qty. to Receive", 0);
        if Abs(SalesLine."Qty. to Invoice") > (Abs(SalesLine."Quantity Shipped") - Abs(SalesLine."Quantity Invoiced")) then
            OldSalesLine.Validate("Qty. to Invoice", SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced")
        else
            OldSalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice");

        OnAddNewSalesLineOnBeforeOldSalesLineModify(OldSalesLine, NewSalesLine, VATProdPostingGroup, GenProdPostingGroup);
        OldSalesLine.Modify();

        OnAfterAddNewSalesLine(OldSalesLine, NewSalesLine);
    end;

    local procedure InitNewSalesLineFromSalesLine(var NewSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; NewLineNo: Integer)
    begin
        NewSalesLine.Init();
        NewSalesLine := SalesLine;
        NewSalesLine."Line No." := NewLineNo;
        NewSalesLine."Quantity Shipped" := 0;
        NewSalesLine."Qty. Shipped (Base)" := 0;
        NewSalesLine."Return Qty. Received" := 0;
        NewSalesLine."Return Qty. Received (Base)" := 0;
        NewSalesLine."Quantity Invoiced" := 0;
        NewSalesLine."Qty. Invoiced (Base)" := 0;
        NewSalesLine."Reserved Quantity" := 0;
        NewSalesLine."Reserved Qty. (Base)" := 0;
        NewSalesLine."Qty. to Ship" := 0;
        NewSalesLine."Qty. to Ship (Base)" := 0;
        NewSalesLine."Return Qty. to Receive" := 0;
        NewSalesLine."Return Qty. to Receive (Base)" := 0;
        NewSalesLine."Qty. to Invoice" := 0;
        NewSalesLine."Qty. to Invoice (Base)" := 0;
        NewSalesLine."Qty. Shipped Not Invoiced" := 0;
        NewSalesLine."Return Qty. Rcd. Not Invd." := 0;
        NewSalesLine."Shipped Not Invoiced" := 0;
        NewSalesLine."Return Rcd. Not Invd." := 0;
        NewSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        NewSalesLine."Ret. Qty. Rcd. Not Invd.(Base)" := 0;
        NewSalesLine."Shipped Not Invoiced (LCY)" := 0;
        NewSalesLine."Return Rcd. Not Invd. (LCY)" := 0;
        OnAfterInitNewSalesLineFromSalesLine(NewSalesLine, SalesLine);
    end;

    local procedure UpdateSalesBlanketOrder(SalesLine: Record "Sales Line"; OriginalLineNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesLine3: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then begin
            SalesLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            SalesLine2.SetRange("Blanket Order No.", SalesLine."Document No.");
            SalesLine2.SetFilter("Blanket Order Line No.", '=%1', OriginalLineNo);
            SalesLine2.SetRange(Type, SalesLine.Type);
            SalesLine2.SetRange("No.", SalesLine."No.");
            SalesLine2.SetRange("Quantity Shipped", 0);
            Clear(SalesHeader);
            if SalesLine2.FindSet() then
                repeat
                    if (SalesHeader."Document Type" <> SalesLine2."Document Type") or
                       (SalesHeader."No." <> SalesLine2."Document No.")
                    then begin
                        SalesHeader.Get(SalesLine2."Document Type", SalesLine2."Document No.");
                        SalesLine3.Reset();
                        SalesLine3.SetRange("Document Type", SalesHeader."Document Type");
                        SalesLine3.SetRange("Document No.", SalesHeader."No.");
                        SalesLine3.SetRange("Blanket Order No.", SalesLine2."Blanket Order No.");
                        SalesLine3.SetRange("Blanket Order Line No.", SalesLine2."Blanket Order Line No.");
                        IsHandled := false;
                        OnUpdateSalesBlanketOrderOnBeforeChangeBlanketOrder(SalesLine3, IsHandled);
                        if not IsHandled then
                            if SalesLine3.FindLast() then begin
                                SalesLine3."Blanket Order Line No." := SalesLine."Line No.";
                                SalesLine3.Modify();
                            end;
                    end;
                until SalesLine2.Next() = 0;
        end;
    end;

    local procedure UpdateAttachedToLineNoSales(SalesLine: Record "Sales Line"; OriginalLineNo: Integer)
    var
        SalesLine2: Record "Sales Line";
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then begin
            SalesLine2.SetRange("Document No.", SalesLine."Document No.");
            SalesLine2.SetRange(Type, SalesLine2.Type::" ");
            SalesLine2.SetRange("Attached to Line No.", OriginalLineNo);
            if not SalesLine2.IsEmpty() then
                SalesLine2.ModifyAll("Attached to Line No.", SalesLine."Line No.");
        end;
    end;

    local procedure UpdateAttachedToLineNoPurch(PurchLine: Record "Purchase Line"; OriginalLineNo: Integer)
    var
        PurchLine2: Record "Purchase Line";
    begin
        if PurchLine."Document Type" = PurchLine."Document Type"::"Blanket Order" then begin
            PurchLine2.SetRange("Document No.", PurchLine."Document No.");
            PurchLine2.SetRange(Type, PurchLine2.Type::" ");
            PurchLine2.SetRange("Attached to Line No.", OriginalLineNo);
            if not PurchLine2.IsEmpty() then
                PurchLine2.ModifyAll("Attached to Line No.", PurchLine."Line No.");
        end;
    end;

    procedure UpdatePurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineOld: Record "Purchase Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        StatusChanged: Boolean;
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
        IsModified: Boolean;
        ShouldProcessLine: Boolean;
    begin
        ProgressWindow.Update(1, PurchaseHeader.TableCaption());

        ConvertVATProdPostingGroup := ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents");
        ConvertGenProdPostingGroup := ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdatePurchase(VATRateChangeSetup, IsHandled, PurchaseHeader);
        if IsHandled then
            exit;

        PurchaseHeader.SetFilter(
          "Document Type", '%1..%2|%3', PurchaseHeader."Document Type"::Quote, PurchaseHeader."Document Type"::Invoice,
          PurchaseHeader."Document Type"::"Blanket Order");
        OnUpdatePurchaseOnAfterPurchaseHeaderSetFilters(PurchaseHeader);
        if PurchaseHeader.Find('-') then
            repeat
                StatusChanged := false;
                if CanUpdatePurchase(PurchaseHeader, ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                    if VATRateChangeSetup."Ignore Status on Purch. Docs." then
                        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then begin
                            PurchaseHeader2 := PurchaseHeader;
                            PurchaseHeader.Status := PurchaseHeader.Status::Open;
                            PurchaseHeader.Modify();
                            StatusChanged := true;
                            OnUpdatePurchaseOnAfterOpenPurchaseHeader(PurchaseHeader);
                        end;
                    if PurchaseHeader.Status = PurchaseHeader.Status::Open then begin
                        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                        OnUpdatePurchaseOnAfterPurchaseLineSetFilters(PurchaseLine, PurchaseHeader);
                        if PurchaseLine.FindSet() then
                            repeat
                                ShouldProcessLine := LineInScope(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup);
                                OnUpdatePurchaseOnAfterCalcShouldProcessLine(PurchaseLine, ShouldProcessLine);
                                if ShouldProcessLine then
                                    if (PurchaseLine."Receipt No." = '') and
                                       (PurchaseLine."Return Shipment No." = '') and IncludePurchLine(PurchaseLine.Type, PurchaseLine."No.")
                                    then
                                        if PurchaseLine.Quantity = PurchaseLine."Outstanding Quantity" then begin
                                            OnUpdatePurchaseOnBeforeChangePurchaseLine(PurchaseLine);

                                            if PurchaseHeader."Prices Including VAT" then
                                                PurchaseLineOld := PurchaseLine;

                                            RecRef.GetTable(PurchaseLine);
                                            UpdateRec(
                                              RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents"),
                                              ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents"));

                                            PurchaseLine.Find();
                                            IsModified := false;
                                            if PurchaseHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                                               (PurchaseLine."VAT %" <> PurchaseLineOld."VAT %") and
                                               UpdateUnitPriceInclVAT(PurchaseLine.Type)
                                            then begin
                                                RecRef.SetTable(PurchaseLine);
                                                RoundingPrecision := GetRoundingPrecision(PurchaseHeader."Currency Code");
                                                PurchaseLine.Validate(
                                                  "Direct Unit Cost",
                                                  Round(
                                                    PurchaseLineOld."Direct Unit Cost" * (100 + PurchaseLine."VAT %") / (100 + PurchaseLineOld."VAT %"),
                                                    RoundingPrecision));
                                                IsModified := true;
                                            end;
                                            if PurchaseLine."Prepayment %" <> 0 then begin
                                                PurchaseLine.UpdatePrepmtSetupFields();
                                                IsModified := true;
                                            end;
                                            OnUpdatePurchaseOnBeforeModifyPurchaseLine(PurchaseLine, IsModified);
                                            if IsModified then begin
                                                PurchaseLine.Modify(true);
                                                OnUpdatePurchaseOnAfterPurchaseLineModify(VATRateChangeSetup, PurchaseHeader, PurchaseLine, PurchaseLineOld);
                                            end;
                                        end else
                                            if VATRateChangeSetup."Perform Conversion" and (PurchaseLine."Outstanding Quantity" <> 0) then begin
                                                NewVATProdPotingGroup := PurchaseLine."VAT Prod. Posting Group";
                                                NewGenProdPostingGroup := PurchaseLine."Gen. Prod. Posting Group";
                                                if ConvertVATProdPostingGroup then
                                                    if VATRateChangeConversion.Get(
                                                         VATRateChangeConversion.Type::"VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group")
                                                    then
                                                        NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                                if ConvertGenProdPostingGroup then
                                                    if VATRateChangeConversion.Get(
                                                         VATRateChangeConversion.Type::"Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group")
                                                    then
                                                        NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                                AddNewPurchaseLine(PurchaseLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                                            end else begin
                                                RecRef.GetTable(PurchaseLine);
                                                InitVATRateChangeLogEntry(
                                                  VATRateChangeLogEntry, RecRef, PurchaseLine."Outstanding Quantity", PurchaseLine."Line No.");
                                                VATRateChangeLogEntry.UpdateGroups(
                                                  PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group",
                                                  PurchaseLine."VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
                                                WriteLogEntry(VATRateChangeLogEntry);
                                            end;
                            until PurchaseLine.Next() = 0;

                        OnUpdatePurchaseOnAfterUpdatePurchaseLines(VATRateChangeSetup, PurchaseHeader, ConvertVATProdPostingGroup, ConvertGenProdPostingGroup);
                    end;
                    if StatusChanged then begin
                        PurchaseHeader.Status := PurchaseHeader2.Status;
                        PurchaseHeader.Modify();
                        OnUpdatePurchaseOnAfterResetPurchaseHeaderStatus(PurchaseHeader);
                    end;
                end;
            until PurchaseHeader.Next() = 0;
    end;

    local procedure CanUpdatePurchase(PurchaseHeader: Record "Purchase Header"; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
    begin
        with PurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            OnCanUpdatePurchaseOnAfterPurchaseLineSetFilters(PurchaseLine);
            if FindSet() then
                repeat
                    DescriptionTxt := '';
                    if LineInScope("Gen. Prod. Posting Group", "VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then begin
                        if "Drop Shipment" and ("Sales Order No." <> '') then
                            DescriptionTxt := StrSubstNo(Text0004, "Line No.");
                        if "Special Order" and ("Special Order Sales No." <> '') then
                            DescriptionTxt := StrSubstNo(Text0005, "Line No.");
                        CheckPurchaseLinePartlyShipped(PurchaseLine, DescriptionTxt);
                        if ("Outstanding Quantity" <> Quantity) and (Type = Type::"Charge (Item)") then
                            DescriptionTxt := StrSubstNo(Text0014, "Line No.", Type::"Charge (Item)");
                        if "Prepmt. Amount Inv. (LCY)" <> 0 then
                            DescriptionTxt := Text0011;
                    end;
                    OnCanUpdatePurchaseOnAfterLoopIteration(DescriptionTxt, PurchaseLine);
                until (Next() = 0) or (DescriptionTxt <> '');
        end;
        if DescriptionTxt = '' then
            exit(true);

        VATRateChangeLogEntry.Init();
        RecRef.GetTable(PurchaseHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure CheckPurchaseLinePartlyShipped(var PurchaseLine: Record "Purchase Line"; var DescriptionTxt: Text[250])
    var
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchaseLinePartlyShipped(PurchaseLine, DescriptionTxt, IsHandled);
        if IsHandled then
            exit;

        with PurchaseLine do
            if ("Outstanding Quantity" <> Quantity) and
               WhseValidateSourceLine.WhseLinesExist(
                 DATABASE::"Purchase Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
            then
                DescriptionTxt := Text0006;
    end;

    local procedure AddNewPurchaseLine(PurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewPurchaseLine: Record "Purchase Line";
        OldPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        OldItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        NewItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        RoundingPrecision: Decimal;
    begin
        if not GetNextPurchaseLineNo(PurchaseLine, NewLineNo) then
            exit;

        with NewPurchaseLine do begin
            Init();
            NewPurchaseLine := PurchaseLine;
            "Line No." := NewLineNo;
            "Quantity Received" := 0;
            "Qty. Received (Base)" := 0;
            "Return Qty. Shipped" := 0;
            "Return Qty. Shipped (Base)" := 0;
            "Quantity Invoiced" := 0;
            "Qty. Invoiced (Base)" := 0;
            "Reserved Quantity" := 0;
            "Reserved Qty. (Base)" := 0;
            "Qty. Rcd. Not Invoiced" := 0;
            "Qty. Rcd. Not Invoiced (Base)" := 0;
            "Return Qty. Shipped Not Invd." := 0;
            "Ret. Qty. Shpd Not Invd.(Base)" := 0;
            "Qty. to Receive" := 0;
            "Qty. to Receive (Base)" := 0;
            "Return Qty. to Ship" := 0;
            "Return Qty. to Ship (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Amt. Rcd. Not Invoiced" := 0;
            "Amt. Rcd. Not Invoiced (LCY)" := 0;
            "Return Shpd. Not Invd." := 0;
            "Return Shpd. Not Invd. (LCY)" := 0;
            OnAddNewPurchaseLineOnAfterNewPurchaseLineInit(OldPurchaseLine, NewPurchaseLine);

            if (GenProdPostingGroup <> '') and ConvertGenProdPostGrp(VATRateChangeSetup."Update Purchase Documents") then
                Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            if (VATProdPostingGroup <> '') and ConvertVATProdPostGrp(VATRateChangeSetup."Update Purchase Documents") then
                Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            Validate(Quantity, PurchaseLine."Outstanding Quantity");
            Validate("Qty. to Receive", PurchaseLine."Qty. to Receive");
            Validate("Return Qty. to Ship", PurchaseLine."Return Qty. to Ship");
            if Abs(PurchaseLine."Qty. to Invoice") > (Abs(PurchaseLine."Quantity Received") - Abs(PurchaseLine."Quantity Invoiced")) then
                Validate(
                  "Qty. to Invoice", PurchaseLine."Qty. to Invoice" - (PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced"))
            else
                Validate("Qty. to Invoice", 0);

            PurchaseHeader.Get("Document Type", "Document No.");
            RoundingPrecision := GetRoundingPrecision(PurchaseHeader."Currency Code");

            if PurchaseHeader."Prices Including VAT" then
                Validate(
                  "Direct Unit Cost",
                  Round(PurchaseLine."Direct Unit Cost" * (100 + "VAT %") / (100 + PurchaseLine."VAT %"), RoundingPrecision))
            else
                Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost");

            Validate("Line Discount %", PurchaseLine."Line Discount %");

            OnAddNewPurchaseLineOnBeforeInsertNewLine(PurchaseLine, NewPurchaseLine);
            Insert();
            OnAddNewPurchaseLineOnAfterInsertNewLine(PurchaseLine, NewPurchaseLine);

            RecRef.GetTable(PurchaseLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(PurchaseLine."Line No."));
            VATRateChangeLogEntry.UpdateGroups(
              PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group",
              PurchaseLine."VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            RecRef.GetTable(NewPurchaseLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              PurchaseLine."Gen. Prod. Posting Group", "Gen. Prod. Posting Group",
              PurchaseLine."VAT Prod. Posting Group", "VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format("Line No."), Format(PurchaseLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);
        end;

        UpdatePurchaseBlanketOrder(NewPurchaseLine, PurchaseLine."Line No.");
        UpdateAttachedToLineNoPurch(NewPurchaseLine, PurchaseLine."Line No.");

        OldReservationEntry.Reset();
        OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        OldReservationEntry.SetRange("Source ID", PurchaseLine."Document No.");
        OldReservationEntry.SetRange("Source Ref. No.", PurchaseLine."Line No.");
        OldReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        OldReservationEntry.SetRange("Source Subtype", PurchaseLine."Document Type");
        OldReservationEntry.SetFilter(
          "Reservation Status", '%1|%2',
          OldReservationEntry."Reservation Status"::Reservation,
          OldReservationEntry."Reservation Status"::Surplus);
        if OldReservationEntry.Find('-') then
            repeat
                NewReservationEntry := OldReservationEntry;
                NewReservationEntry."Source Ref. No." := NewLineNo;
                NewReservationEntry.Modify();
            until OldReservationEntry.Next() = 0;

        case PurchaseLine.Type of
            PurchaseLine.Type::Item:
                begin
                    OldItemChargeAssignmentPurch.Reset();
                    OldItemChargeAssignmentPurch.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", PurchaseLine."Document Type");
                    OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", PurchaseLine."Document No.");
                    OldItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", PurchaseLine."Line No.");
                    if OldItemChargeAssignmentPurch.FindSet() then
                        repeat
                            QtyRemainder := OldItemChargeAssignmentPurch."Qty. to Assign";
                            AmountRemainder := OldItemChargeAssignmentPurch."Amount to Assign";
                            NewItemChargeAssignmentPurch := OldItemChargeAssignmentPurch;
                            NewItemChargeAssignmentPurch."Line No." := GetNextItemChrgAssPurchLineNo(OldItemChargeAssignmentPurch);
                            NewItemChargeAssignmentPurch."Applies-to Doc. Line No." := NewLineNo;
                            NewItemChargeAssignmentPurch."Qty. to Assign" :=
                              Round(QtyRemainder / PurchaseLine.Quantity * PurchaseLine."Outstanding Quantity", UOMMgt.QtyRndPrecision());
                            if PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced" = 0 then
                                NewItemChargeAssignmentPurch."Qty. to Assign" := QtyRemainder;
                            NewItemChargeAssignmentPurch."Amount to Assign" :=
                              Round(NewItemChargeAssignmentPurch."Qty. to Assign" * NewItemChargeAssignmentPurch."Unit Cost", RoundingPrecision);
                            NewItemChargeAssignmentPurch.Insert();
                            QtyRemainder := QtyRemainder - NewItemChargeAssignmentPurch."Qty. to Assign";
                            AmountRemainder := AmountRemainder - NewItemChargeAssignmentPurch."Amount to Assign";
                            OldItemChargeAssignmentPurch."Qty. to Assign" := QtyRemainder;
                            OldItemChargeAssignmentPurch."Amount to Assign" := AmountRemainder;
                            OldItemChargeAssignmentPurch.Modify();
                        until OldItemChargeAssignmentPurch.Next() = 0;
                end;
        end;

        OldPurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        OldPurchaseLine.Validate("Qty. to Receive", 0);
        OldPurchaseLine.Validate(Quantity, PurchaseLine."Quantity Received");

        OldPurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost");

        OldPurchaseLine.Validate("Line Discount %", PurchaseLine."Line Discount %");
        OldPurchaseLine.Validate("Return Qty. to Ship", 0);
        if Abs(PurchaseLine."Qty. to Invoice") > (Abs(PurchaseLine."Quantity Received") - Abs(PurchaseLine."Quantity Invoiced")) then
            OldPurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Quantity Received" - PurchaseLine."Quantity Invoiced")
        else
            OldPurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice");

        OnAddNewPurchaseLineOnBeforeOldPurchaseLineModify(OldPurchaseLine, NewPurchaseLine, VATProdPostingGroup, GenProdPostingGroup);
        OldPurchaseLine.Modify();

        OnAfterAddNewPurchaseLine(OldPurchaseLine, NewPurchaseLine);
    end;

    procedure GetNextPurchaseLineNo(PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer): Boolean
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        PurchaseLine2.Reset();
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine2 := PurchaseLine;
        if PurchaseLine2.Find('>') then
            NextLineNo := PurchaseLine."Line No." + (PurchaseLine2."Line No." - PurchaseLine."Line No.") div 2;
        if (NextLineNo = PurchaseLine."Line No.") or (NextLineNo = 0) then begin
            PurchaseLine2.FindLast();
            NextLineNo := PurchaseLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> PurchaseLine."Line No.");
    end;

    local procedure UpdatePurchaseBlanketOrder(PurchaseLine: Record "Purchase Line"; OriginalLineNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Blanket Order" then begin
            PurchaseLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchaseLine2.SetRange("Blanket Order No.", PurchaseLine."Document No.");
            PurchaseLine2.SetFilter("Blanket Order Line No.", '=%1', OriginalLineNo);
            PurchaseLine2.SetRange(Type, PurchaseLine.Type);
            PurchaseLine2.SetRange("No.", PurchaseLine."No.");
            PurchaseLine2.SetRange("Quantity Received", 0);
            Clear(PurchaseHeader);
            if PurchaseLine2.Find('-') then
                repeat
                    if (PurchaseHeader."Document Type" <> PurchaseLine2."Document Type") or
                       (PurchaseHeader."No." <> PurchaseLine2."Document No.")
                    then begin
                        PurchaseHeader.Get(PurchaseLine2."Document Type", PurchaseLine2."Document No.");
                        PurchaseLine3.Reset();
                        PurchaseLine3.SetRange("Document Type", PurchaseHeader."Document Type");
                        PurchaseLine3.SetRange("Document No.", PurchaseHeader."No.");
                        PurchaseLine3.SetRange("Blanket Order No.", PurchaseLine2."Blanket Order No.");
                        PurchaseLine3.SetRange("Blanket Order Line No.", PurchaseLine2."Blanket Order Line No.");
                        IsHandled := false;
                        OnUpdatePurchaseBlanketOrderOnBeforeChangeBlanketOrder(PurchaseLine, IsHandled);
                        if not IsHandled then
                            if PurchaseLine3.FindLast() then begin
                                PurchaseLine3."Blanket Order Line No." := PurchaseLine."Line No.";
                                PurchaseLine3.Modify();
                            end;
                    end;
                until PurchaseLine2.Next() = 0;
        end;
    end;

    procedure UpdateUnitPriceInclVAT(Type: Enum "Sales Line Type"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        exit(
          ((VATRateChangeSetup."Update Unit Price For G/L Acc." and
            (Type = SalesLine.Type::"G/L Account")) or
           (VATRateChangeSetup."Upd. Unit Price For Item Chrg." and
            (Type = SalesLine.Type::"Charge (Item)")) or
           (VATRateChangeSetup."Upd. Unit Price For FA" and (Type = SalesLine.Type::"Fixed Asset"))));
    end;

    procedure LineInScope(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean) Result: Boolean
    begin
        if ConvertGenProdPostingGroup then
            if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"Gen. Prod. Posting Group", GenProdPostingGroup) then
                Result := true;
        if ConvertVATProdPostingGroup then
            if VATRateChangeConversion.Get(VATRateChangeConversion.Type::"VAT Prod. Posting Group", VATProdPostingGroup) then
                Result := true;
        OnAfterLineInScope(GenProdPostingGroup, VATProdPostingGroup, ConvertGenProdPostingGroup, ConvertVATProdPostingGroup, Result)
    end;

    procedure GetNextSalesLineNo(SalesLine: Record "Sales Line"; var NextLineNo: Integer): Boolean
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2 := SalesLine;
        if SalesLine2.Find('>') then
            NextLineNo := SalesLine."Line No." + (SalesLine2."Line No." - SalesLine."Line No.") div 2;
        if (NextLineNo = SalesLine."Line No.") or (NextLineNo = 0) then begin
            SalesLine2.FindLast();
            NextLineNo := SalesLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> SalesLine."Line No.");
    end;

    local procedure UpdateServPriceAdjDetail()
    var
        VatRateChangeConversion: Record "VAT Rate Change Conversion";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        ServPriceAdjustmentDetailNew: Record "Serv. Price Adjustment Detail";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServPriceAdjDetail(VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        if VATRateChangeSetup."Update Serv. Price Adj. Detail" <>
           VATRateChangeSetup."Update Serv. Price Adj. Detail"::"Gen. Prod. Posting Group"
        then
            exit;
        VatRateChangeConversion.SetRange(Type, VatRateChangeConversion.Type::"Gen. Prod. Posting Group");
        if VatRateChangeConversion.FindSet() then
            repeat
                with ServPriceAdjustmentDetail do begin
                    SetRange("Gen. Prod. Posting Group", VatRateChangeConversion."From Code");
                    if FindSet() then
                        repeat
                            VATRateChangeLogEntry.Init();
                            RecRef.GetTable(ServPriceAdjustmentDetailNew);
                            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
                            VATRateChangeLogEntry."Table ID" := DATABASE::"Serv. Price Adjustment Detail";
                            VATRateChangeLogEntry."Old Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
                            VATRateChangeLogEntry."New Gen. Prod. Posting Group" := VatRateChangeConversion."To Code";
                            ServPriceAdjustmentDetailNew := ServPriceAdjustmentDetail;
                            if VATRateChangeSetup."Perform Conversion" then begin
                                ServPriceAdjustmentDetailNew.Rename(
                                  "Serv. Price Adjmt. Gr. Code", Type, "No.", "Work Type", VatRateChangeConversion."To Code");
                                VATRateChangeLogEntry.Converted := true
                            end else
                                VATRateChangeLogEntry.Description := StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
                            WriteLogEntry(VATRateChangeLogEntry);
                        until Next() = 0;
                end;
            until VatRateChangeConversion.Next() = 0;
    end;

    procedure GetRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
        exit(Currency."Unit-Amount Rounding Precision");
    end;

    local procedure CanUpdateService(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceHeader: Record "Service Header";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        DescriptionTxt: Text[250];
    begin
        DescriptionTxt := '';
        with ServiceLine do
            if "Shipment No." <> '' then
                DescriptionTxt := Text0010;
        if DescriptionTxt = '' then
            exit(true);

        VATRateChangeLogEntry.Init();
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        RecRef.GetTable(ServiceHeader);
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        VATRateChangeLogEntry.Description := DescriptionTxt;
        WriteLogEntry(VATRateChangeLogEntry);
    end;

    local procedure UpdateService()
    var
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineOld: Record "Service Line";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewVATProdPotingGroup: Code[20];
        NewGenProdPostingGroup: Code[20];
        ConvertVATProdPostingGroup: Boolean;
        ConvertGenProdPostingGroup: Boolean;
        ServiceHeaderStatusChanged: Boolean;
        RoundingPrecision: Decimal;
        LastDocNo: Code[20];
        IsHandled: Boolean;
    begin
        ProgressWindow.Update(1, ServiceLine.TableCaption());
        ConvertVATProdPostingGroup := ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs.");
        ConvertGenProdPostingGroup := ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs.");
        if not ConvertVATProdPostingGroup and not ConvertGenProdPostingGroup then
            exit;

        IsHandled := false;
        OnBeforeUpdateService(VATRateChangeSetup, IsHandled);
        if IsHandled then
            exit;

        with ServiceLine do begin
            SetFilter("Document Type", '%1|%2|%3', "Document Type"::Quote, "Document Type"::Order, "Document Type"::Invoice);
            SetRange("Shipment No.", '');
            LastDocNo := '';
            if Find('-') then
                repeat
                    if LineInScope("Gen. Prod. Posting Group", "VAT Prod. Posting Group", ConvertGenProdPostingGroup, ConvertVATProdPostingGroup) then
                        if CanUpdateService(ServiceLine) and IncludeServiceLine(Type, "No.") then begin
                            if LastDocNo <> "Document No." then begin
                                ServiceHeader.Get("Document Type", "Document No.");
                                LastDocNo := ServiceHeader."No.";
                            end;

                            if VATRateChangeSetup."Ignore Status on Service Docs." then
                                if ServiceHeader."Release Status" <> ServiceHeader."Release Status"::Open then begin
                                    ServiceHeader2 := ServiceHeader;
                                    ServiceHeader."Release Status" := ServiceHeader."Release Status"::Open;
                                    ServiceHeader.Modify();
                                    ServiceHeaderStatusChanged := true;
                                end;

                            if Quantity = "Outstanding Quantity" then begin
                                if ServiceHeader."Prices Including VAT" then
                                    ServiceLineOld := ServiceLine;

                                RecRef.GetTable(ServiceLine);
                                UpdateRec(
                                  RecRef, ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs."),
                                  ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs."));

                                Find();
                                if ServiceHeader."Prices Including VAT" and VATRateChangeSetup."Perform Conversion" and
                                   ("VAT %" <> ServiceLineOld."VAT %") and
                                   VATRateChangeSetup."Update Unit Price For G/L Acc." and
                                   (Type = Type::"G/L Account")
                                then begin
                                    RecRef.SetTable(ServiceLine);
                                    RoundingPrecision := GetRoundingPrecision(ServiceHeader."Currency Code");
                                    Validate("Unit Price", Round("Unit Price" * (100 + "VAT %") / (100 + ServiceLineOld."VAT %"), RoundingPrecision));
                                    Modify(true);
                                end;
                            end else
                                if VATRateChangeSetup."Perform Conversion" and ("Outstanding Quantity" <> 0) then begin
                                    NewVATProdPotingGroup := "VAT Prod. Posting Group";
                                    NewGenProdPostingGroup := "Gen. Prod. Posting Group";
                                    if ConvertVATProdPostingGroup then
                                        if VATRateChangeConversion.Get(
                                             VATRateChangeConversion.Type::"VAT Prod. Posting Group", "VAT Prod. Posting Group")
                                        then
                                            NewVATProdPotingGroup := VATRateChangeConversion."To Code";
                                    if ConvertGenProdPostingGroup then
                                        if VATRateChangeConversion.Get(
                                             VATRateChangeConversion.Type::"Gen. Prod. Posting Group", "Gen. Prod. Posting Group")
                                        then
                                            NewGenProdPostingGroup := VATRateChangeConversion."To Code";
                                    AddNewServiceLine(ServiceLine, NewVATProdPotingGroup, NewGenProdPostingGroup);
                                end else begin
                                    RecRef.GetTable(ServiceLine);
                                    InitVATRateChangeLogEntry(VATRateChangeLogEntry, RecRef, "Outstanding Quantity", "Line No.");
                                    VATRateChangeLogEntry.UpdateGroups(
                                      "Gen. Prod. Posting Group", "Gen. Prod. Posting Group", "VAT Prod. Posting Group", "VAT Prod. Posting Group");
                                    WriteLogEntry(VATRateChangeLogEntry);
                                end;

                            if ServiceHeaderStatusChanged then begin
                                ServiceHeader."Release Status" := ServiceHeader2."Release Status";
                                ServiceHeader.Modify();
                                ServiceHeaderStatusChanged := false;
                            end;
                        end;
                until Next() = 0;
        end;
    end;

    local procedure AddNewServiceLine(ServiceLine: Record "Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NewServiceLine: Record "Service Line";
        OldServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        OldReservationEntry: Record "Reservation Entry";
        NewReservationEntry: Record "Reservation Entry";
        VATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        RecRef: RecordRef;
        NewLineNo: Integer;
        RoundingPrecision: Decimal;
    begin
        if not GetNextServiceLineNo(ServiceLine, NewLineNo) then
            exit;

        with NewServiceLine do begin
            Init();
            NewServiceLine := ServiceLine;
            "Line No." := NewLineNo;
            "Qty. to Invoice" := 0;
            "Qty. to Ship" := 0;
            "Qty. Shipped Not Invoiced" := 0;
            "Quantity Shipped" := 0;
            "Quantity Invoiced" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Qty. to Ship (Base)" := 0;
            "Qty. Shipped Not Invd. (Base)" := 0;
            "Qty. Shipped (Base)" := 0;
            "Qty. Invoiced (Base)" := 0;
            "Qty. to Consume" := 0;
            "Quantity Consumed" := 0;
            "Qty. to Consume (Base)" := 0;
            "Qty. Consumed (Base)" := 0;
            if (GenProdPostingGroup <> '') and ConvertGenProdPostGrp(VATRateChangeSetup."Update Service Docs.") then
                Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
            if (VATProdPostingGroup <> '') and ConvertVATProdPostGrp(VATRateChangeSetup."Update Service Docs.") then
                Validate("VAT Prod. Posting Group", VATProdPostingGroup);

            Validate(Quantity, ServiceLine."Outstanding Quantity");
            Validate("Qty. to Ship", ServiceLine."Qty. to Ship");
            Validate("Qty. to Consume", ServiceLine."Qty. to Consume");
            if Abs(ServiceLine."Qty. to Invoice") >
               (Abs(ServiceLine."Quantity Shipped") - Abs(ServiceLine."Quantity Invoiced"))
            then
                Validate(
                  "Qty. to Invoice",
                  ServiceLine."Qty. to Invoice" - (ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced"))
            else
                Validate("Qty. to Invoice", 0);
            ServiceHeader.Get("Document Type", "Document No.");
            RoundingPrecision := GetRoundingPrecision(ServiceHeader."Currency Code");
            if ServiceHeader."Prices Including VAT" then
                Validate("Unit Price", Round(ServiceLine."Unit Price" * (100 + "VAT %") / (100 + ServiceLine."VAT %"), RoundingPrecision))
            else
                Validate("Unit Price", ServiceLine."Unit Price");
            Validate("Line Discount %", ServiceLine."Line Discount %");
            Insert();
            RecRef.GetTable(ServiceLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.Description := StrSubstNo(Text0012, Format(ServiceLine."Line No."));
            VATRateChangeLogEntry.UpdateGroups(
              ServiceLine."Gen. Prod. Posting Group", ServiceLine."Gen. Prod. Posting Group",
              ServiceLine."VAT Prod. Posting Group", ServiceLine."VAT Prod. Posting Group");
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);

            RecRef.GetTable(NewServiceLine);
            VATRateChangeLogEntry.Init();
            VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
            VATRateChangeLogEntry."Table ID" := RecRef.Number;
            VATRateChangeLogEntry.UpdateGroups(
              ServiceLine."Gen. Prod. Posting Group", "Gen. Prod. Posting Group",
              ServiceLine."VAT Prod. Posting Group", "VAT Prod. Posting Group");
            VATRateChangeLogEntry.Description := StrSubstNo(Text0013, Format("Line No."), Format(ServiceLine."Line No."));
            VATRateChangeLogEntry.Converted := true;
            WriteLogEntry(VATRateChangeLogEntry);
        end;

        ServiceLine.CalcFields("Reserved Quantity");
        if ServiceLine."Reserved Quantity" <> 0 then begin
            OldReservationEntry.Reset();
            OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
            OldReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
            OldReservationEntry.SetRange("Source Ref. No.", ServiceLine."Line No.");
            OldReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
            OldReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
            OldReservationEntry.SetRange("Reservation Status", OldReservationEntry."Reservation Status"::Reservation);
            if OldReservationEntry.FindSet() then
                repeat
                    NewReservationEntry := OldReservationEntry;
                    NewReservationEntry."Source Ref. No." := NewLineNo;
                    NewReservationEntry.Modify();
                until OldReservationEntry.Next() = 0;
        end;

        OldReservationEntry.Reset();
        OldReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype");
        OldReservationEntry.SetRange("Source ID", ServiceLine."Document No.");
        OldReservationEntry.SetRange("Source Ref. No.", ServiceLine."Line No.");
        OldReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        OldReservationEntry.SetRange("Source Subtype", ServiceLine."Document Type");
        OldReservationEntry.SetRange("Reservation Status", OldReservationEntry."Reservation Status"::Surplus);
        if OldReservationEntry.Find('-') then
            repeat
                NewReservationEntry := OldReservationEntry;
                NewReservationEntry."Source Ref. No." := NewLineNo;
                NewReservationEntry.Modify();
            until OldReservationEntry.Next() = 0;

        OldServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        OldServiceLine.Validate(Quantity, ServiceLine."Quantity Shipped");
        OldServiceLine.Validate("Unit Price", ServiceLine."Unit Price");
        OldServiceLine.Validate("Line Discount %", ServiceLine."Line Discount %");
        OldServiceLine.Validate("Qty. to Ship", 0);
        OldServiceLine.Validate("Qty. to Consume", 0);
        if Abs(OldServiceLine."Qty. to Invoice") >
           (Abs(OldServiceLine."Quantity Shipped") - Abs(OldServiceLine."Quantity Consumed") - Abs(ServiceLine."Quantity Invoiced"))
        then
            OldServiceLine.Validate(
              "Qty. to Invoice", OldServiceLine."Qty. to Invoice" - ServiceLine."Quantity Shipped" - OldServiceLine."Quantity Consumed")
        else
            OldServiceLine.Validate("Qty. to Invoice", OldServiceLine."Qty. to Invoice");

        OnAddNewServiceLineOnBeforeOldServiceLineModify(OldServiceLine, NewServiceLine, VATProdPostingGroup, GenProdPostingGroup);
        OldServiceLine.Modify();
    end;

    procedure GetNextServiceLineNo(ServiceLine: Record "Service Line"; var NextLineNo: Integer): Boolean
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.Reset();
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2 := ServiceLine;
        if ServiceLine2.Find('>') then
            NextLineNo := ServiceLine."Line No." + (ServiceLine2."Line No." - ServiceLine."Line No.") div 2;
        if (NextLineNo = ServiceLine."Line No.") or (NextLineNo = 0) then begin
            ServiceLine2.FindLast();
            NextLineNo := ServiceLine2."Line No." + 10000;
        end;
        exit(NextLineNo <> ServiceLine."Line No.");
    end;

    local procedure GetNextItemChrgAssSaleLineNo(ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"): Integer
    var
        ItemChargeAssignmentSales2: Record "Item Charge Assignment (Sales)";
        ExitValue: Integer;
    begin
        ExitValue := 10000;
        ItemChargeAssignmentSales2.Reset();
        ItemChargeAssignmentSales2.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssignmentSales2.SetRange("Document Type", ItemChargeAssignmentSales."Document Type");
        ItemChargeAssignmentSales2.SetRange("Document No.", ItemChargeAssignmentSales."Document No.");
        ItemChargeAssignmentSales2.SetRange("Document Line No.", ItemChargeAssignmentSales."Document Line No.");
        if ItemChargeAssignmentSales2.FindLast() then
            ExitValue := ItemChargeAssignmentSales2."Line No." + 10000;
        exit(ExitValue);
    end;

    local procedure GetNextItemChrgAssPurchLineNo(ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"): Integer
    var
        ItemChargeAssignmentPurch2: Record "Item Charge Assignment (Purch)";
        ExitValue: Integer;
    begin
        ExitValue := 10000;
        ItemChargeAssignmentPurch2.Reset();
        ItemChargeAssignmentPurch2.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssignmentPurch2.SetRange("Document Type", ItemChargeAssignmentPurch."Document Type");
        ItemChargeAssignmentPurch2.SetRange("Document No.", ItemChargeAssignmentPurch."Document No.");
        ItemChargeAssignmentPurch2.SetRange("Document Line No.", ItemChargeAssignmentPurch."Document Line No.");
        if ItemChargeAssignmentPurch2.FindLast() then
            ExitValue := ItemChargeAssignmentPurch2."Line No." + 10000;
        exit(ExitValue);
    end;

    local procedure AreTablesSelected() Result: Boolean
    begin
        with VATRateChangeSetup do begin
            if "Update Gen. Prod. Post. Groups" <> "Update Gen. Prod. Post. Groups"::No then
                exit(true);
            if "Update G/L Accounts" <> "Update G/L Accounts"::No then
                exit(true);
            if "Update Items" <> "Update Items"::No then
                exit(true);
            if "Update Item Templates" <> "Update Item Templates"::No then
                exit(true);
            if "Update Item Charges" <> "Update Item Charges"::No then
                exit(true);
            if "Update Resources" <> "Update Resources"::No then
                exit(true);
            if "Update Gen. Journal Lines" <> "Update Gen. Journal Lines"::No then
                exit(true);
            if "Update Gen. Journal Allocation" <> "Update Gen. Journal Allocation"::No then
                exit(true);
            if "Update Std. Gen. Jnl. Lines" <> "Update Std. Gen. Jnl. Lines"::No then
                exit(true);
            if "Update Res. Journal Lines" <> "Update Res. Journal Lines"::No then
                exit(true);
            if "Update Job Journal Lines" <> "Update Job Journal Lines"::No then
                exit(true);
            if "Update Requisition Lines" <> "Update Requisition Lines"::No then
                exit(true);
            if "Update Std. Item Jnl. Lines" <> "Update Std. Item Jnl. Lines"::No then
                exit(true);
            if "Update Service Docs." <> "Update Service Docs."::No then
                exit(true);
            if "Update Serv. Price Adj. Detail" <> "Update Serv. Price Adj. Detail"::No then
                exit(true);
            if "Update Sales Documents" <> "Update Sales Documents"::No then
                exit(true);
            if "Update Purchase Documents" <> "Update Purchase Documents"::No then
                exit(true);
            if "Update Production Orders" <> "Update Production Orders"::No then
                exit(true);
            if "Update Work Centers" <> "Update Work Centers"::No then
                exit(true);
            if "Update Machine Centers" <> "Update Machine Centers"::No then
                exit(true);
            if "Update Reminders" <> "Update Reminders"::No then
                exit(true);
            if "Update Finance Charge Memos" <> "Update Finance Charge Memos"::No then
                exit(true);
        end;
        Result := false;

        OnAfterAreTablesSelected(VATRateChangeSetup, Result);
    end;

#if not CLEAN22
    [Obsolete('Replaced by procedures IncludeSalesLine() and IncludePurchLine()', '22.0')]
    procedure IncludeLine(Type: Option " ","G/L Account",Item,Resource; No: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        case Type of
            Type::"G/L Account":
                exit(IncludeGLAccount(No));
            Type::Item:
                exit(IncludeItem(No));
            Type::Resource:
                exit(IncludeRes(No));
        end;
        exit(true);
    end;
#endif

    procedure IncludeSalesLine(Type: Enum "Sales Line Type"; No: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        case Type of
            "Sales Line Type"::"G/L Account":
                exit(IncludeGLAccount(No));
            "Sales Line Type"::Item:
                exit(IncludeItem(No));
            "Sales Line Type"::Resource:
                exit(IncludeRes(No));
            else begin
                IsHandled := false;
                OnIncludeSalesLineOnTypeElse(Type, Result, IsHandled);
                if IsHandled then
                    exit(Result);
            end;
        end;
        exit(true);
    end;

    procedure IncludePurchLine(Type: Enum "Purchase Line Type"; No: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        case Type of
            "Purchase Line Type"::"G/L Account":
                exit(IncludeGLAccount(No));
            "Purchase Line Type"::Item:
                exit(IncludeItem(No));
            "Purchase Line Type"::Resource:
                exit(IncludeRes(No));
            else begin
                IsHandled := false;
                OnIncludePurchLineOnTypeElse(Type, Result, IsHandled);
                if IsHandled then
                    exit(Result);
            end;
        end;
        exit(true);
    end;

    local procedure IncludeGLAccount(No: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if VATRateChangeSetup."Account Filter" = '' then
            exit(true);
        GLAccount."No." := No;
        GLAccount.SetFilter("No.", VATRateChangeSetup."Account Filter");
        exit(GLAccount.Find());
    end;

    local procedure IncludeItem(No: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if VATRateChangeSetup."Item Filter" = '' then
            exit(true);
        Item."No." := No;
        Item.SetFilter("No.", VATRateChangeSetup."Item Filter");
        exit(Item.Find());
    end;

    local procedure IncludeRes(No: Code[20]): Boolean
    var
        Res: Record Resource;
    begin
        if VATRateChangeSetup."Resource Filter" = '' then
            exit(true);
        Res."No." := No;
        Res.SetFilter("No.", VATRateChangeSetup."Resource Filter");
        exit(Res.Find());
    end;

    local procedure IncludeServiceLine(Type: Enum "Service Line Type"; No: Code[20]): Boolean
    begin
        case Type of
            Type::"G/L Account":
                exit(IncludeGLAccount(No));
            Type::Item:
                exit(IncludeItem(No));
            Type::Resource:
                exit(IncludeRes(No));
        end;
        exit(true);
    end;

    procedure InitVATRateChangeLogEntry(var VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; RecRef: RecordRef; OutstandingQuantity: Decimal; LineNo: Integer)
    begin
        VATRateChangeLogEntry.Init();
        VATRateChangeLogEntry."Record ID" := RecRef.RecordId;
        VATRateChangeLogEntry."Table ID" := RecRef.Number;
        if (OutstandingQuantity = 0) and VATRateChangeSetup."Perform Conversion" then
            VATRateChangeLogEntry.Description := Text0007
        else begin
            VATRateChangeLogEntry.Description :=
              StrSubstNo(Text0009, VATRateChangeSetup.FieldCaption("Perform Conversion"));
            if OutstandingQuantity <> 0 then
                VATRateChangeLogEntry.Description := StrSubstNo(Text0017, LineNo)
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnBeforeOldPurchaseLineModify(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewSalesLineOnBeforeOldSalesLineModify(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewServiceLineOnBeforeOldServiceLineModify(var OldServiceLine: Record "Service Line"; var NewServiceLine: Record "Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewSalesLineFromSalesLine(var NewSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateTables(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterLineInScope(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; ConvertGenProdPostingGroup: Boolean; ConvertVATProdPostingGroup: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAreTablesSelected(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchaseLinePartlyShipped(var PurchaseLine: Record "Purchase Line"; var DescriptionTxt: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLinePartlyShipped(var SalesLine: Record "Sales Line"; var DescriptionTxt: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFinishConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var ProgressWindow: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGLAccount(var GLAccount: Record "G/L Account"; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateItem(var Item: Record Item; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateResource(var Resource: Record Resource; var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSales(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTable(TableID: Integer; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchase(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServPriceAdjDetail(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateService(var VATRateChangeSetup: Record "VAT Rate Change Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRec(var RecRef: RecordRef; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertOnBeforeStartConvert(var VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddNewSalesLine(var OldSalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddNewPurchaseLine(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseHeaderSetFilters(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseLineSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnBeforeRecRefModify(var RecRef: RecordRef; GenProdPostingGroupConverted: Boolean; VATProdPostingGroupConverted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRecOnAfterRecRefModify(var RecRef: RecordRef; GenProdPostingGroupConverted: Boolean; VATProdPostingGroupConverted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterSalesHeaderSetFilters(VATRateChangeSetup: Record "VAT Rate Change Setup"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterSalesLineSetFilters(VATRateChangeSetup: Record "VAT Rate Change Setup"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterModifySalesLine(var SalesLine: Record "Sales Line"; IsModified: Boolean; VATRateChangeSetup: Record "VAT Rate Change Setup"; SalesHeader: Record "Sales Header"; SalesLineOld: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateSalesOnAfterUpdateSalesLines(VATRateChangeSetup: Record "VAT Rate Change Setup"; var SalesHeader: Record "Sales Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterResetPurchaseHeaderStatus(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterCalcShouldProcessLine(var PurchaseLine: Record "Purchase Line"; var ShouldProcessLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterResetSalesHeaderStatus(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; var IsModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; var IsModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnAfterInsertNewLine(var PurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnBeforeInsertNewLine(var PurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewSalesLineOnAfterInsertNewLine(var SalesLine: Record "Sales Line"; var NewSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnBeforeChangeSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnBeforeChangePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseBlanketOrderOnBeforeChangeBlanketOrder(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesBlanketOrderOnBeforeChangeBlanketOrder(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterOpenPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesOnAfterOpenSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdatePurchaseOnAfterUpdatePurchaseLines(VATRateChangeSetup: Record "VAT Rate Change Setup"; var PurchaseHeader: Record "Purchase Header"; ConvertVATProdPostingGroup: Boolean; ConvertGenProdPostingGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestVATPostingSetupOnAfterVATPostingSetupOldSetFilters(var VATPostingSetupOld: Record "VAT Posting Setup"; VATRateChangeSetup: Record "VAT Rate Change Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateRecOnBeforeValidateGenProdPostingGroup(var RecRef: RecordRef; FldRef: FieldRef; VatRateChangeConversion: Record "VAT Rate Change Conversion"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddNewPurchaseLineOnAfterNewPurchaseLineInit(var OldPurchaseLine: Record "Purchase Line"; var NewPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseOnAfterPurchaseLineModify(VATRateChangeSetup: Record "VAT Rate Change Setup"; PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchaseLineOld: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnIncludePurchLineOnTypeElse(Type: Enum "Purchase Line Type"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnIncludeSalesLineOnTypeElse(Type: Enum "Sales Line Type"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdatePurchaseOnAfterLoopIteration(var DescriptionTxt: Text[250]; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdatePurchaseOnAfterPurchaseLineSetFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdateSalesOnAfterLoopIteration(var DescriptionTxt: Text[250]; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanUpdateSalesOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;
}

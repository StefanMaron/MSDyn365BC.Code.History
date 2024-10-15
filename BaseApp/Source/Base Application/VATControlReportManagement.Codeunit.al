codeunit 31100 VATControlReportManagement
{
    Permissions = TableData "VAT Entry" = rm,
                  TableData "VAT Posting Setup" = r,
                  TableData "VAT Control Report Header" = rimd,
                  TableData "VAT Control Report Line" = rimd,
                  TableData "VAT Control Report Section" = r;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        StatReportingSetup: Record "Stat. Reporting Setup";
        TempBudgetBufVATEntry: Record "Budget Buffer" temporary;
        TempBudgetBufDocument: Record "Budget Buffer" temporary;
        TempErrorBuf: Record "Error Buffer" temporary;
        TempVATEntryGlobal: Record "VAT Entry" temporary;
        Window: Dialog;
        ProgressDialogMsg: Label 'VAT Statement Line Progress     #1######## #2######## #3########', Comment = '%1=Statement Template Name;%2=Statement Name;%3=Line No.';
        BufferCreateDialogMsg: Label 'VAT Control report     #1########', Comment = '%1=Statement Template Name';
        LineCreatedMsg: Label '%1 Lines have been created.', Comment = '%1=not of created lines';
        CloseVATControlRepHeaderQst: Label 'Really close lines of VAT Control Report No. %1?', Comment = '%1=VAT Control Report No.';
        LinesNotExistErr: Label 'There is nothing to close for VAT Control Report No. %1.', Comment = '%1=VAT Control Report No.';
        IsInitialized: Boolean;
        GlobalLineNo: Integer;
        InternalDocCheckMsg: Label 'There is nothing internal document to exclusion in VAT Control Report No. %1.', Comment = '%1=VAT Control Report No.';
        AmountTxt: Label 'Amount';
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)', '15.3')]
        PerformCountryRegionCode: Code[10];

    [Scope('OnPrem')]
    procedure GetVATCtrlReportLines(VATCtrlRptHdr: Record "VAT Control Report Header"; StartDate: Date; EndDate: Date; VATStmTemplCode: Code[10]; VATStmName: Code[10]; ProcessType: Option Add,Rewrite; ShowMessage: Boolean; UseMergeVATEntries: Boolean)
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATCtrlRptSection: Record "VAT Control Report Section";
        VATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link";
        TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary;
        TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary;
        TempVATCtrlRepVATEntryLink2: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempVATEntryActual: Record "VAT Entry" temporary;
        TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementLine: Record "VAT Statement Line";
        DocumentAmount: Decimal;
        i: Integer;
    begin
        if VATCtrlRptHdr."No." = '' then
            exit;

        GLSetup.Get();
        StatReportingSetup.Get();
        if ProcessType = ProcessType::Rewrite then
            DeleteVATCtrlReportLines(VATCtrlRptHdr, StartDate, EndDate);

        TempVATCtrlRepVATEntryLink.SetCurrentKey("VAT Entry No.");
        TempVATCtrlRepVATEntryLink2.SetCurrentKey("VAT Entry No.");

        if ShowMessage then
            Window.Open(ProgressDialogMsg);

        PerformCountryRegionCode := VATCtrlRptHdr."Perform. Country/Region Code";

        VATStatementLine.SetRange("Statement Template Name", VATStmTemplCode);
        VATStatementLine.SetRange("Statement Name", VATStmName);
        VATStatementLine.SetFilter("VAT Control Rep. Section Code", '<>%1', '');
        if VATStatementLine.FindSet(false, false) then
            repeat
                if ShowMessage then begin
                    Window.Update(1, VATStatementLine."Statement Template Name");
                    Window.Update(2, VATStatementLine."Statement Name");
                    Window.Update(3, VATStatementLine."Line No.");
                end;

                GetVATEntryBufferForVATStatementLine(TempVATEntry, VATStatementLine, VATCtrlRptHdr, StartDate, EndDate);

                TempVATEntry.Reset();
                if TempVATEntry.FindSet then
                    repeat
                        with TempVATEntry do begin
                            TempVATCtrlRepVATEntryLink.SetRange("VAT Entry No.", "Entry No."); // exist in used VAT Entries
                            TempVATCtrlRepVATEntryLink2.SetRange("VAT Entry No.", "Entry No."); // exist in merged VAT Entries
                            if (not TempVATCtrlRepVATEntryLink.FindFirst) and
                               (not TempVATCtrlRepVATEntryLink2.FindFirst)
                            then begin
                                if ("VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
                                   ("VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group")
                                then begin
                                    VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                                    VATPostingSetup.TestField("VAT Rate");
                                end;

                                if VATCtrlRptSection.Code <> VATStatementLine."VAT Control Rep. Section Code" then
                                    VATCtrlRptSection.Get(VATStatementLine."VAT Control Rep. Section Code");

                                if UseMergeVATEntries then
                                    MergeVATEntry(TempVATEntry, TempVATCtrlRepVATEntryLink2)
                                else begin
                                    Base -= "VAT Amount (Non Deductible)";
                                    Amount += "VAT Amount (Non Deductible)";
                                end;

                                DocumentAmount := GetDocumentAmount(
                                    TempVATEntry, VATCtrlRptSection."Group By" = VATCtrlRptSection."Group By"::"External Document No.");
                                if ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") and
                                   (Abs(DocumentAmount) <= StatReportingSetup."Simplified Tax Document Limit") and
                                   (VATPostingSetup."Corrections for Bad Receivable" = VATPostingSetup."Corrections for Bad Receivable"::" ") and
                                   (VATCtrlRptSection."Simplified Tax Doc. Sect. Code" <> '') and
                                   (not VATStatementLine."Ignore Simpl. Tax Doc. Limit")
                                then
                                    VATCtrlRptSection.Get(VATCtrlRptSection."Simplified Tax Doc. Sect. Code");

                                case VATCtrlRptSection.Code of
                                    'A1', 'B1':
                                        begin
                                            MergeVATEntry(TempVATEntry, TempVATCtrlRepVATEntryLink2);
                                            GetBufferFromDocument(TempVATEntry, TempDropShptPostBuffer, VATCtrlRptSection.Code);
                                            TempDropShptPostBuffer.Reset();
                                            TempVATEntryActual := TempVATEntry;
                                            if TempDropShptPostBuffer.FindSet then
                                                repeat
                                                    // VAT Entry Amount Set
                                                    if TempDropShptPostBuffer.Count > 1 then
                                                        if (TempVATEntryActual.Base + TempVATEntryActual.Amount) < 0 then begin
                                                            Base := Abs(TempDropShptPostBuffer.Quantity) * -1;
                                                            Amount := Abs(TempDropShptPostBuffer."Quantity (Base)") * -1;
                                                        end else begin
                                                            Base := Abs(TempDropShptPostBuffer.Quantity);
                                                            Amount := Abs(TempDropShptPostBuffer."Quantity (Base)");
                                                        end;

                                                    case VATCtrlRptSection."Group By" of
                                                        VATCtrlRptSection."Group By"::"Document No.":
                                                            InsertVATCtrlRptBufferDocNo(TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry,
                                                              VATPostingSetup, VATCtrlRptSection.Code, TempDropShptPostBuffer."Order No.");
                                                        VATCtrlRptSection."Group By"::"External Document No.":
                                                            InsertVATCtrlRptBufferExtDocNo(TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry,
                                                              VATPostingSetup, VATCtrlRptSection.Code, TempDropShptPostBuffer."Order No.");
                                                        VATCtrlRptSection."Group By"::"Section Code":
                                                            InsertVATCtrlRptBufferDocNo(TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry,
                                                              VATPostingSetup, VATCtrlRptSection.Code, TempDropShptPostBuffer."Order No.");
                                                    end;
                                                until TempDropShptPostBuffer.Next = 0;
                                        end;
                                    else
                                        case VATCtrlRptSection."Group By" of
                                            VATCtrlRptSection."Group By"::"Document No.":
                                                InsertVATCtrlRptBufferDocNo(
                                                  TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry, VATPostingSetup, VATCtrlRptSection.Code, '');
                                            VATCtrlRptSection."Group By"::"External Document No.":
                                                InsertVATCtrlRptBufferExtDocNo(
                                                  TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry, VATPostingSetup, VATCtrlRptSection.Code, '');
                                            VATCtrlRptSection."Group By"::"Section Code":
                                                InsertVATCtrlRptBufferDocNo(
                                                  TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink, TempVATEntry, VATPostingSetup, VATCtrlRptSection.Code, '');
                                        end;
                                end;
                            end;
                        end;
                    until TempVATEntry.Next = 0;
            until VATStatementLine.Next = 0;

        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        if not VATCtrlRptLn.FindLast then
            Clear(VATCtrlRptLn);

        TempVATCtrlRptBuf.Reset();
        TempVATCtrlRepVATEntryLink.Reset();
        TempVATCtrlRepVATEntryLink2.Reset();
        TempVATCtrlRepVATEntryLink.SetCurrentKey("Line No.");
        TempVATCtrlRepVATEntryLink2.SetCurrentKey("Line No.");
        if TempVATCtrlRptBuf.FindSet then
            repeat
                // line
                VATCtrlRptLn.Init();
                VATCtrlRptLn."Control Report No." := VATCtrlRptHdr."No.";
                VATCtrlRptLn."Line No." += 1;
                CopyBufferToLine(TempVATCtrlRptBuf, VATCtrlRptLn);
                if (VATCtrlRptLn.Base <> 0) or (VATCtrlRptLn.Amount <> 0) then begin
                    VATCtrlRptLn.Insert();
                    i += 1;

                    // link to VAT Entries
                    TempVATCtrlRepVATEntryLink.SetRange("Line No.", TempVATCtrlRptBuf."Line No.");
                    if TempVATCtrlRepVATEntryLink.FindSet then
                        repeat
                            // VAT Control Line to VAT Entry Link
                            VATCtrlRepVATEntryLink.Init();
                            VATCtrlRepVATEntryLink."Control Report No." := VATCtrlRptLn."Control Report No.";
                            VATCtrlRepVATEntryLink."Line No." := VATCtrlRptLn."Line No.";
                            VATCtrlRepVATEntryLink."VAT Entry No." := TempVATCtrlRepVATEntryLink."VAT Entry No.";
                            VATCtrlRepVATEntryLink.Insert();

                            // VAT Entry Merge Link
                            TempVATCtrlRepVATEntryLink2.SetRange("Line No.", TempVATCtrlRepVATEntryLink."VAT Entry No.");
                            if TempVATCtrlRepVATEntryLink2.FindSet then
                                repeat
                                    VATCtrlRepVATEntryLink.Init();
                                    VATCtrlRepVATEntryLink."Control Report No." := VATCtrlRptLn."Control Report No.";
                                    VATCtrlRepVATEntryLink."Line No." := VATCtrlRptLn."Line No.";
                                    VATCtrlRepVATEntryLink."VAT Entry No." := TempVATCtrlRepVATEntryLink2."VAT Entry No.";
                                    VATCtrlRepVATEntryLink.Insert();
                                until TempVATCtrlRepVATEntryLink2.Next = 0;
                        until TempVATCtrlRepVATEntryLink.Next = 0;
                end;
            until TempVATCtrlRptBuf.Next = 0;

        if ShowMessage then begin
            Window.Close;
            Message(LineCreatedMsg, i);
        end;
    end;

    local procedure MergeVATEntry(var TempVATEntry: Record "VAT Entry" temporary; var TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary)
    begin
        with TempBudgetBufVATEntry do begin
            Reset;
            SetRange("G/L Account No.", TempVATEntry."Document No.");
            SetRange("Dimension Value Code 1", Format(TempVATEntry."VAT Calculation Type", 0, '<Number>'));
            SetRange("Dimension Value Code 2", TempVATEntry."VAT Bus. Posting Group");
            SetRange("Dimension Value Code 3", TempVATEntry."VAT Prod. Posting Group");
            SetRange("Dimension Value Code 4", Format(TempVATEntry.Type, 0, '<Number>'));
            SetRange("Dimension Value Code 5", TempVATEntry."VAT Registration No.");
            SetRange("Dimension Value Code 6", CopyStr(TempVATEntry."External Document No.", 1, MaxStrLen("Dimension Value Code 6")));
            if StrLen(TempVATEntry."External Document No.") > MaxStrLen("Dimension Value Code 6") then
                SetRange("Dimension Value Code 7", CopyStr(TempVATEntry."External Document No.", MaxStrLen("Dimension Value Code 6") + 1));
            SetRange(Date, TempVATEntry."Posting Date");
            if not FindFirst then begin
                TempVATEntryGlobal.Reset();
                TempVATEntryGlobal.SetCurrentKey("Document No.");
                TempVATEntryGlobal.SetRange("Document No.", TempVATEntry."Document No.");
                TempVATEntryGlobal.SetRange("VAT Bus. Posting Group", TempVATEntry."VAT Bus. Posting Group");
                TempVATEntryGlobal.SetRange("VAT Prod. Posting Group", TempVATEntry."VAT Prod. Posting Group");
                TempVATEntryGlobal.SetRange(Type, TempVATEntry.Type);
                TempVATEntryGlobal.SetRange("VAT Registration No.", TempVATEntry."VAT Registration No.");
                TempVATEntryGlobal.SetRange("External Document No.", TempVATEntry."External Document No.");
                TempVATEntryGlobal.SetRange("Posting Date", TempVATEntry."Posting Date");
                if TempVATEntry."VAT Calculation Type" <> TempVATEntry."VAT Calculation Type"::"Reverse Charge VAT" then
                    TempVATEntryGlobal.SetFilter(Amount, '<>0');
                if TempVATEntryGlobal.FindSet then begin
                    Init;
                    "G/L Account No." := TempVATEntry."Document No.";
                    "Dimension Value Code 1" := Format(TempVATEntry."VAT Calculation Type", 0, '<Number>');
                    "Dimension Value Code 2" := TempVATEntry."VAT Bus. Posting Group";
                    "Dimension Value Code 3" := TempVATEntry."VAT Prod. Posting Group";
                    "Dimension Value Code 4" := Format(TempVATEntry.Type, 0, '<Number>');
                    "Dimension Value Code 5" := TempVATEntry."VAT Registration No.";
                    "Dimension Value Code 6" := CopyStr(TempVATEntry."External Document No.", 1, MaxStrLen("Dimension Value Code 6"));
                    "Dimension Value Code 7" := CopyStr(TempVATEntry."External Document No.", MaxStrLen("Dimension Value Code 6") + 1);
                    Date := TempVATEntry."Posting Date";

                    TempVATEntry.Base := 0;
                    TempVATEntry.Amount := 0;
                    TempVATEntry."Advance Base" := 0;
                    repeat
                        TempVATEntry.Base += TempVATEntryGlobal.Base - TempVATEntryGlobal."VAT Amount (Non Deductible)";
                        TempVATEntry.Amount += TempVATEntryGlobal.Amount + TempVATEntryGlobal."VAT Amount (Non Deductible)";
                        TempVATEntry."Advance Base" += TempVATEntryGlobal."Advance Base";

                        if TempVATEntryGlobal."Entry No." <> TempVATEntry."Entry No." then begin
                            TempVATCtrlRepVATEntryLink."Control Report No." := '';
                            TempVATCtrlRepVATEntryLink."Line No." := TempVATEntry."Entry No.";
                            TempVATCtrlRepVATEntryLink."VAT Entry No." := TempVATEntryGlobal."Entry No.";
                            TempVATCtrlRepVATEntryLink.Insert();
                        end;
                    until TempVATEntryGlobal.Next = 0;
                    Insert;
                end;
            end;
        end;
    end;

    local procedure GetDocumentAmount(var TempVATEntry: Record "VAT Entry" temporary; ExternalDocument: Boolean): Decimal
    begin
        with TempBudgetBufDocument do begin
            Reset;
            if not ExternalDocument or (TempVATEntry."External Document No." = '') then
                SetRange("G/L Account No.", TempVATEntry."Document No.")
            else begin
                SetRange("Dimension Value Code 6", CopyStr(TempVATEntry."External Document No.", 1, MaxStrLen("Dimension Value Code 6")));
                SetRange("Dimension Value Code 7", CopyStr(TempVATEntry."External Document No.", MaxStrLen("Dimension Value Code 6") + 1));
            end;
            if not IsDocumentWithReverseChargeVAT(TempVATEntry."Document No.", TempVATEntry."Posting Date") then
                SetRange("Dimension Value Code 1", Format(TempVATEntry."VAT Calculation Type", 0, '<Number>'));
            SetRange("Dimension Value Code 2", Format(TempVATEntry.Type, 0, '<Number>'));
            SetRange("Dimension Value Code 3", TempVATEntry."Bill-to/Pay-to No.");
            SetRange(Date, TempVATEntry."Posting Date");
            if not FindFirst then begin
                TempVATEntryGlobal.Reset();
                if not ExternalDocument or (TempVATEntry."External Document No." = '') then
                    TempVATEntryGlobal.SetRange("Document No.", TempVATEntry."Document No.")
                else
                    TempVATEntryGlobal.SetRange("External Document No.", TempVATEntry."External Document No.");
                TempVATEntryGlobal.SetRange("Bill-to/Pay-to No.", TempVATEntry."Bill-to/Pay-to No.");
                TempVATEntryGlobal.SetRange("Posting Date", TempVATEntry."Posting Date");
                TempVATEntryGlobal.SetRange(Type, TempVATEntry.Type);
                if TempVATEntryGlobal.FindSet then begin
                    Init;
                    if not ExternalDocument or (TempVATEntry."External Document No." = '') then
                        "G/L Account No." := TempVATEntry."Document No."
                    else begin
                        "Dimension Value Code 6" := CopyStr(TempVATEntry."External Document No.", 1, MaxStrLen("Dimension Value Code 6"));
                        "Dimension Value Code 7" := CopyStr(TempVATEntry."External Document No.", MaxStrLen("Dimension Value Code 6") + 1);
                    end;
                    "Dimension Value Code 1" := Format(TempVATEntry."VAT Calculation Type", 0, '<Number>');
                    "Dimension Value Code 2" := Format(TempVATEntry.Type, 0, '<Number>');
                    "Dimension Value Code 3" := TempVATEntry."Bill-to/Pay-to No.";
                    Date := TempVATEntry."Posting Date";
                    repeat
                        if TempVATEntryGlobal."VAT Calculation Type" = TempVATEntryGlobal."VAT Calculation Type"::"Reverse Charge VAT" then
                            Amount += TempVATEntryGlobal.Base
                        else
                            if (TempVATEntryGlobal."Prepayment Type" = TempVATEntryGlobal."Prepayment Type"::Advance) and
                               (TempVATEntryGlobal."Advance Base" <> 0)
                            then
                                Amount += (TempVATEntryGlobal."Advance Base" + TempVATEntryGlobal.Amount)
                            else
                                Amount += (TempVATEntryGlobal.Base + TempVATEntryGlobal.Amount);
                    until TempVATEntryGlobal.Next = 0;
                    Insert;
                end;
            end;
            exit(Amount);
        end;
    end;

    local procedure IsDocumentWithReverseChargeVAT(DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        TempVATEntryGlobal.Reset();
        TempVATEntryGlobal.SetCurrentKey("Document No.");
        TempVATEntryGlobal.SetRange("Document No.", DocumentNo);
        TempVATEntryGlobal.SetRange("Posting Date", PostingDate);
        TempVATEntryGlobal.SetRange("VAT Calculation Type", TempVATEntryGlobal."VAT Calculation Type"::"Reverse Charge VAT");
        exit(not TempVATEntryGlobal.IsEmpty);
    end;

    local procedure DeleteVATCtrlReportLines(VATCtrlRptHdr: Record "VAT Control Report Header"; StartDate: Date; EndDate: Date)
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
    begin
        if VATCtrlRptHdr."No." = '' then
            exit;
        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        if GLSetup."Use VAT Date" then begin
            VATCtrlRptLn.SetCurrentKey("Control Report No.", "VAT Date");
            VATCtrlRptLn.SetRange("VAT Date", StartDate, EndDate);
        end else begin
            VATCtrlRptLn.SetCurrentKey("Control Report No.", "Posting Date");
            VATCtrlRptLn.SetRange("Posting Date", StartDate, EndDate);
        end;
        VATCtrlRptLn.SetFilter("Closed by Document No.", '%1', '');
        if not VATCtrlRptLn.IsEmpty then
            VATCtrlRptLn.DeleteAll(true);
    end;

    local procedure InsertVATCtrlRptBufferDocNo(var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; var TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary; VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; SectionCode: Code[20]; CommodityCode: Code[20])
    begin
        with TempVATCtrlRptBuf do begin
            Reset;
            SetCurrentKey("Document No.");
            SetRange("Document No.", VATEntry."Document No.");
            InsertVATCtrlRptBufferGroup(TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink,
              VATEntry, VATPostingSetup, SectionCode, CommodityCode);
        end;
    end;

    local procedure InsertVATCtrlRptBufferExtDocNo(var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; var TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary; VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; SectionCode: Code[20]; CommodityCode: Code[20])
    begin
        with TempVATCtrlRptBuf do begin
            Reset;
            if VATEntry."External Document No." <> '' then begin
                SetRange("External Document No.", VATEntry."External Document No.");
                SetRange("Original Document VAT Date", VATEntry."Original Document VAT Date");
            end else begin
                SetCurrentKey("Document No.");
                SetRange("Document No.", VATEntry."Document No.");
            end;
            InsertVATCtrlRptBufferGroup(TempVATCtrlRptBuf, TempVATCtrlRepVATEntryLink,
              VATEntry, VATPostingSetup, SectionCode, CommodityCode);
        end;
    end;

    local procedure InsertVATCtrlRptBufferGroup(var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; var TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary; VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; SectionCode: Code[20]; CommodityCode: Code[20])
    begin
        with TempVATCtrlRptBuf do begin
            SetRange("VAT Control Rep. Section Code", SectionCode);
            SetRange("VAT Rate", VATPostingSetup."VAT Rate");
            SetRange("Commodity Code", CommodityCode);
            SetRange("VAT Registration No.", VATEntry."VAT Registration No.");
            SetRange("Supplies Mode Code", VATPostingSetup."Supplies Mode Code");
            SetRange("Corrections for Bad Receivable", VATPostingSetup."Corrections for Bad Receivable");
            SetRange("Ratio Use", VATPostingSetup."Ratio Coefficient");
            if not FindFirst then
                InsertVATCtrlRptBuffer(TempVATCtrlRptBuf, VATEntry, VATPostingSetup, SectionCode, CommodityCode)
            else begin
                if VATEntry."Advance Base" <> 0 then
                    VATEntry.Base += VATEntry."Advance Base";
                "Total Base" += VATEntry.Base;
                "Total Amount" += VATEntry.Amount;
                Modify;
            end;

            InsertVATCtrlRepVATEntryLink(TempVATCtrlRepVATEntryLink, "Line No.", VATEntry."Entry No.");
        end;
    end;

    local procedure InsertVATCtrlRptBuffer(var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; VATEntry: Record "VAT Entry"; VATPostingSetup2: Record "VAT Posting Setup"; SectionCode: Code[20]; CommodityCode: Code[20])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        with TempVATCtrlRptBuf do begin
            Init;
            "VAT Control Rep. Section Code" := SectionCode;
            GlobalLineNo += 1;
            "Line No." := GlobalLineNo;
            "Posting Date" := VATEntry."Posting Date";
            "VAT Date" := VATEntry."VAT Date";
            "Original Document VAT Date" := VATEntry."Original Document VAT Date";
            "Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
            "VAT Registration No." := VATEntry."VAT Registration No.";
            case VATEntry.Type of
                VATEntry.Type::Purchase:
                    if Vend.Get("Bill-to/Pay-to No.") then begin
                        "Tax Registration No." := Vend."Tax Registration No.";
                        "Registration No." := Vend."Registration No.";
                    end;
                VATEntry.Type::Sale:
                    if Cust.Get("Bill-to/Pay-to No.") then begin
                        "Tax Registration No." := Cust."Tax Registration No.";
                        "Registration No." := Cust."Registration No.";
                    end;
            end;
            "Document No." := VATEntry."Document No.";
            "External Document No." := VATEntry."External Document No.";
            Type := VATEntry.Type;
            "VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
            "VAT Calculation Type" := VATEntry."VAT Calculation Type";
            "VAT Rate" := VATPostingSetup2."VAT Rate";
            "Commodity Code" := CopyStr(CommodityCode, 1, MaxStrLen("Commodity Code"));
            "Supplies Mode Code" := VATPostingSetup2."Supplies Mode Code";
            "Corrections for Bad Receivable" := VATPostingSetup2."Corrections for Bad Receivable";
            "Ratio Use" := VATPostingSetup2."Ratio Coefficient";
            if VATEntry."Advance Base" <> 0 then
                VATEntry.Base += VATEntry."Advance Base";
            "Total Base" := VATEntry.Base;
            "Total Amount" := VATEntry.Amount;
            Insert;
        end;
    end;

    local procedure InsertVATCtrlRepVATEntryLink(var TempVATCtrlRepVATEntryLink: Record "VAT Ctrl.Rep. - VAT Entry Link" temporary; LineNo: Integer; VATEntryNo: Integer): Boolean
    begin
        TempVATCtrlRepVATEntryLink."Line No." := LineNo;
        TempVATCtrlRepVATEntryLink."VAT Entry No." := VATEntryNo;
        exit(TempVATCtrlRepVATEntryLink.Insert); // vat entry split
    end;

    local procedure SkipVATEntry(VATEntry: Record "VAT Entry"): Boolean
    begin
        with VATEntry do begin
            if "VAT Control Report Line No." <> 0 then
                exit(true);
            if not "Postponed VAT" then
                exit(false);
            if Base <> 0 then
                exit(false);
            if "Unrealized Base" = 0 then
                exit(false);
            exit(IsVATEntryCorrected(VATEntry));
        end;
    end;

    local procedure IsVATEntryCorrected(VATEntry: Record "VAT Entry"): Boolean
    begin
        with VATEntry do begin
            TempVATEntryGlobal.Reset();
            TempVATEntryGlobal.SetCurrentKey("Document No.");
            TempVATEntryGlobal.SetRange("Document No.", "Document No.");
            TempVATEntryGlobal.SetRange("Document Type", "Document Type");
            TempVATEntryGlobal.SetRange(Type, Type);
            TempVATEntryGlobal.SetRange(Base, "Unrealized Base");
            TempVATEntryGlobal.SetRange(Amount, "Unrealized Amount");
            exit(not TempVATEntryGlobal.IsEmpty);
        end;
    end;

    local procedure GetBufferFromDocument(VATEntry: Record "VAT Entry"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; SectionCode: Code[20])
    begin
        TempDropShptPostBuffer.Reset();
        TempDropShptPostBuffer.DeleteAll();

        with VATEntry do begin
            if (Base <> 0) or (Amount <> 0) or ("Advance Base" <> 0) then
                case SectionCode of
                    'A1':
                        begin
                            TestField(Type, Type::Sale);
                            case "Document Type" of
                                "Document Type"::Invoice:
                                    SplitFromSalesInvLine(VATEntry, TempDropShptPostBuffer);
                                "Document Type"::"Credit Memo":
                                    SplitFromSalesCrMemoLine(VATEntry, TempDropShptPostBuffer);
                            end;
                        end;
                    'B1':
                        begin
                            TestField(Type, Type::Purchase);
                            case "Document Type" of
                                "Document Type"::Invoice:
                                    SplitFromPurchInvLine(VATEntry, TempDropShptPostBuffer);
                                "Document Type"::"Credit Memo":
                                    SplitFromPurchCrMemoLine(VATEntry, TempDropShptPostBuffer);
                            end;
                        end;
                    else
                        exit;
                end;

            if not TempDropShptPostBuffer.FindFirst then begin
                TempDropShptPostBuffer.Init();
                TempDropShptPostBuffer."Order No." := '';
                if "Advance Base" <> 0 then
                    TempDropShptPostBuffer.Quantity := "Advance Base"
                else
                    TempDropShptPostBuffer.Quantity := Base;
                TempDropShptPostBuffer."Quantity (Base)" := Amount;
                TempDropShptPostBuffer.Insert();
            end;
        end;
    end;

    local procedure SplitFromSalesInvLine(VATEntry: Record "VAT Entry"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesInvHdr: Record "Sales Invoice Header";
        SalesInvLn: Record "Sales Invoice Line";
    begin
        with SalesInvLn do begin
            SetRange("Document No.", VATEntry."Document No.");
            SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then begin
                SalesInvHdr.Get("Document No.");
                repeat
                    UpdateTempDropShptPostBuffer(TempDropShptPostBuffer, "Tariff No.",
                      "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Base Amount",
                      SalesInvHdr."Currency Code", SalesInvHdr."VAT Currency Factor", SalesInvHdr."VAT Date",
                      false, Amount);
                until Next = 0;
            end;
        end;
    end;

    local procedure SplitFromSalesCrMemoLine(VATEntry: Record "VAT Entry"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLn: Record "Sales Cr.Memo Line";
    begin
        with SalesCrMemoLn do begin
            SetRange("Document No.", VATEntry."Document No.");
            SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then begin
                SalesCrMemoHdr.Get("Document No.");
                repeat
                    UpdateTempDropShptPostBuffer(TempDropShptPostBuffer, "Tariff No.",
                      "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Base Amount",
                      SalesCrMemoHdr."Currency Code", SalesCrMemoHdr."VAT Currency Factor", SalesCrMemoHdr."VAT Date",
                      false, Amount);
                until Next = 0;
            end;
        end;
    end;

    local procedure SplitFromPurchInvLine(VATEntry: Record "VAT Entry"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchInvLn: Record "Purch. Inv. Line";
    begin
        with PurchInvLn do begin
            SetRange("Document No.", VATEntry."Document No.");
            SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then begin
                PurchInvHdr.Get("Document No.");
                repeat
                    UpdateTempDropShptPostBuffer(TempDropShptPostBuffer, "Tariff No.",
                      "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Base Amount",
                      PurchInvHdr."Currency Code", PurchInvHdr."VAT Currency Factor", PurchInvHdr."VAT Date",
                      true, Amount);
                until Next = 0;
            end;
        end;
    end;

    local procedure SplitFromPurchCrMemoLine(VATEntry: Record "VAT Entry"; var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLn: Record "Purch. Cr. Memo Line";
    begin
        with PurchCrMemoLn do begin
            SetRange("Document No.", VATEntry."Document No.");
            SetRange("VAT Bus. Posting Group", VATEntry."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", VATEntry."VAT Prod. Posting Group");
            SetFilter(Type, '<>%1', Type::" ");
            SetFilter(Quantity, '<>0');
            if FindSet(false, false) then begin
                PurchCrMemoHdr.Get("Document No.");
                repeat
                    UpdateTempDropShptPostBuffer(TempDropShptPostBuffer, "Tariff No.",
                      "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Base Amount",
                      PurchCrMemoHdr."Currency Code", PurchCrMemoHdr."VAT Currency Factor", PurchCrMemoHdr."VAT Date",
                      true, Amount);
                until Next = 0;
            end;
        end;
    end;

    local procedure UpdateTempDropShptPostBuffer(var TempDropShptPostBuffer: Record "Drop Shpt. Post. Buffer" temporary; TariffNo: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATBaseAmount: Decimal; CurrencyCode: Code[10]; VATCurrencyFactor: Decimal; VATDate: Date; CalcQtyBase: Boolean; LineAmount: Decimal)
    var
        TariffNumber: Record "Tariff Number";
    begin
        with TempDropShptPostBuffer do begin
            if not TariffNumber.Get(TariffNo) then
                TariffNumber.Init();
            if not Get(TariffNumber."Statement Code") then begin
                Init;
                "Order No." := TariffNumber."Statement Code";
                Insert;
            end;
            if PerformCountryRegionCode <> '' then begin
                Quantity += PerfCurrExchangeAmount(VATBaseAmount, VATDate, CurrencyCode);
                if CalcQtyBase then
                    "Quantity (Base)" += PerfCurrExchangeAmount(LineAmount, VATDate, CurrencyCode)
                else
                    "Quantity (Base)" := 0;
                Modify;
                exit;
            end;
            Quantity += CalcVATBaseAmtLCY(
                VATBusPostingGroup,
                VATProdPostingGroup,
                VATBaseAmount,
                CurrencyCode,
                VATCurrencyFactor,
                VATDate);
            if CalcQtyBase then
                "Quantity (Base)" += CalcVATAmtLCY(
                    CalcVATAmt(VATBusPostingGroup, VATProdPostingGroup, LineAmount),
                    CurrencyCode,
                    VATCurrencyFactor,
                    VATDate)
            else
                "Quantity (Base)" := 0;
            Modify;
        end;
    end;

    local procedure CalcVATBaseAmtLCY(VATBusPstGroup: Code[20]; VATProdPstGroup: Code[20]; VATBaseAmt: Decimal; CurrCode: Code[10]; CurrFactor: Decimal; PostingDate: Date) VATBaseAmtLCY: Decimal
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        VATBaseAmtLCY := 0;

        if CurrCode = '' then
            VATBaseAmtLCY := VATBaseAmt
        else begin
            TempGenJnlLine.Init();
            TempGenJnlLine.Validate("VAT Bus. Posting Group", VATBusPstGroup);
            TempGenJnlLine.Validate("VAT Prod. Posting Group", VATProdPstGroup);
            TempGenJnlLine.Validate("Posting Date", PostingDate);
            TempGenJnlLine.Validate("Currency Code", CurrCode);
            TempGenJnlLine.Validate("Currency Factor", CurrFactor);
            TempGenJnlLine.Validate("VAT Base Amount", VATBaseAmt);
            VATBaseAmtLCY := TempGenJnlLine."VAT Base Amount (LCY)";
        end;
    end;

    local procedure CalcVATAmtLCY(VATAmt: Decimal; CurrCode: Code[10]; CurrFactor: Decimal; PostingDate: Date) VATAmtLCY: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        VATAmtLCY := 0;

        if CurrCode = '' then
            VATAmtLCY := VATAmt
        else
            VATAmtLCY := CurrExchRate.ExchangeAmtFCYToLCY(PostingDate, CurrCode, VATAmt, CurrFactor);
    end;

    local procedure CalcVATAmt(VATBusPstGroup: Code[20]; VATProdPstGroup: Code[20]; Amt: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPstGroup, VATProdPstGroup);
        exit(Amt * VATPostingSetup."VAT %" / 100);
    end;

    [Scope('OnPrem')]
    procedure CreateBufferForStatistics(VATCtrlRptHdr: Record "VAT Control Report Header"; var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; ShowMessage: Boolean)
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
    begin
        if VATCtrlRptHdr."No." = '' then
            exit;

        TempVATCtrlRptBuf.Reset();
        TempVATCtrlRptBuf.DeleteAll();

        if ShowMessage then begin
            Window.Open(BufferCreateDialogMsg);
            Window.Update(1, VATCtrlRptHdr."No.");
        end;

        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        VATCtrlRptLn.SetRange("Exclude from Export", false);
        if VATCtrlRptLn.FindSet then
            repeat
                if not TempVATCtrlRptBuf.Get(VATCtrlRptLn."VAT Control Rep. Section Code") then begin
                    TempVATCtrlRptBuf.Init();
                    TempVATCtrlRptBuf."VAT Control Rep. Section Code" := VATCtrlRptLn."VAT Control Rep. Section Code";
                    TempVATCtrlRptBuf.Insert();
                end;
                case VATCtrlRptLn."VAT Rate" of
                    VATCtrlRptLn."VAT Rate"::Base:
                        begin
                            TempVATCtrlRptBuf."Base 1" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 1" += VATCtrlRptLn.Amount;
                        end;
                    VATCtrlRptLn."VAT Rate"::Reduced:
                        begin
                            TempVATCtrlRptBuf."Base 2" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 2" += VATCtrlRptLn.Amount;
                        end;
                    VATCtrlRptLn."VAT Rate"::"Reduced 2":
                        begin
                            TempVATCtrlRptBuf."Base 3" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 3" += VATCtrlRptLn.Amount;
                        end;
                end;
                if VATCtrlRptLn."VAT Rate" > VATCtrlRptLn."VAT Rate"::" " then begin
                    TempVATCtrlRptBuf."Total Base" += VATCtrlRptLn.Base;
                    TempVATCtrlRptBuf."Total Amount" += VATCtrlRptLn.Amount;
                end;
                OnBeforeModifyVATCtrlReportBufferForStatistics(TempVATCtrlRptBuf, VATCtrlRptLn);
                TempVATCtrlRptBuf.Modify();
            until VATCtrlRptLn.Next = 0;

        if ShowMessage then
            Window.Close;
    end;

    [Scope('OnPrem')]
    procedure CreateBufferForExport(VATCtrlRptHdr: Record "VAT Control Report Header"; var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; ShowMessage: Boolean; EntriesSelection: Enum "VAT Statement Report Selection")
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
        VATCtrlRptSection: Record "VAT Control Report Section";
        LineNo: Integer;
    begin
        if VATCtrlRptHdr."No." = '' then
            exit;

        GLSetup.Get();

        TempVATCtrlRptBuf.Reset();
        TempVATCtrlRptBuf.DeleteAll();

        if ShowMessage then begin
            Window.Open(BufferCreateDialogMsg);
            Window.Update(1, VATCtrlRptHdr."No.");
        end;

        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        VATCtrlRptLn.SetRange("Exclude from Export", false);
        case EntriesSelection of
            EntriesSelection::Open:
                VATCtrlRptLn.SetFilter("Closed by Document No.", '%1', '');
            EntriesSelection::Closed:
                VATCtrlRptLn.SetFilter("Closed by Document No.", '<>%1', '');
            EntriesSelection::"Open and Closed":
                VATCtrlRptLn.SetRange("Closed by Document No.");
        end;
        if VATCtrlRptLn.FindSet then
            repeat
                if VATCtrlRptSection.Code <> VATCtrlRptLn."VAT Control Rep. Section Code" then
                    VATCtrlRptSection.Get(VATCtrlRptLn."VAT Control Rep. Section Code");

                TempVATCtrlRptBuf.Reset();
                TempVATCtrlRptBuf.SetCurrentKey("Document No.", "Posting Date");
                TempVATCtrlRptBuf.SetRange("VAT Control Rep. Section Code", VATCtrlRptLn."VAT Control Rep. Section Code");

                if not (VATCtrlRptSection.Code in ['A5', 'B3']) then begin
                    TempVATCtrlRptBuf.SetRange("Commodity Code", VATCtrlRptLn."Commodity Code");
                    TempVATCtrlRptBuf.SetRange("Supplies Mode Code", VATCtrlRptLn."Supplies Mode Code");
                    TempVATCtrlRptBuf.SETRANGE("Corrections for Bad Receivable", VATCtrlRptLn."Corrections for Bad Receivable");
                    TempVATCtrlRptBuf.SetRange("Ratio Use", VATCtrlRptLn."Ratio Use");

                    case VATCtrlRptSection."Group By" of
                        VATCtrlRptSection."Group By"::"Document No.":
                            begin
                                TempVATCtrlRptBuf.SetRange("Document No.", VATCtrlRptLn."Document No.");
                                TempVATCtrlRptBuf.SetRange("Bill-to/Pay-to No.", VATCtrlRptLn."Bill-to/Pay-to No.");
                            end;
                        VATCtrlRptSection."Group By"::"External Document No.":
                            begin
                                TempVATCtrlRptBuf.SetRange("Document No.", VATCtrlRptLn."External Document No.");
                                TempVATCtrlRptBuf.SetRange("Bill-to/Pay-to No.", VATCtrlRptLn."Bill-to/Pay-to No.");
                            end;
                        VATCtrlRptSection."Group By"::"Section Code":
                            ;
                    end;

                    if VATCtrlRptSection."Group By" <> VATCtrlRptSection."Group By"::"Section Code" then begin
                        if GLSetup."Use VAT Date" then
                            TempVATCtrlRptBuf.SetRange("Posting Date", VATCtrlRptLn."VAT Date")
                        else
                            TempVATCtrlRptBuf.SetRange("Posting Date", VATCtrlRptLn."Posting Date");
                    end;
                end;

                if not TempVATCtrlRptBuf.FindFirst then begin
                    CopyLineToBuffer(VATCtrlRptLn, TempVATCtrlRptBuf);
                    LineNo += 1;
                    TempVATCtrlRptBuf."Line No." := LineNo;
                    if GLSetup."Use VAT Date" then begin
                        TempVATCtrlRptBuf."VAT Date" := VATCtrlRptLn."VAT Date";
                        TempVATCtrlRptBuf."Posting Date" := VATCtrlRptLn."VAT Date";
                        TempVATCtrlRptBuf."Original Document VAT Date" := VATCtrlRptLn."Original Document VAT Date";
                    end else begin
                        TempVATCtrlRptBuf."VAT Date" := VATCtrlRptLn."Posting Date";
                        TempVATCtrlRptBuf."Posting Date" := VATCtrlRptLn."Posting Date";
                        TempVATCtrlRptBuf."Original Document VAT Date" := VATCtrlRptLn."Original Document VAT Date";
                    end;
                    TempVATCtrlRptBuf.Insert();
                end;

                case VATCtrlRptLn."VAT Rate" of
                    VATCtrlRptLn."VAT Rate"::Base:
                        begin
                            TempVATCtrlRptBuf."Base 1" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 1" += VATCtrlRptLn.Amount;
                        end;
                    VATCtrlRptLn."VAT Rate"::Reduced:
                        begin
                            TempVATCtrlRptBuf."Base 2" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 2" += VATCtrlRptLn.Amount;
                        end;
                    VATCtrlRptLn."VAT Rate"::"Reduced 2":
                        begin
                            TempVATCtrlRptBuf."Base 3" += VATCtrlRptLn.Base;
                            TempVATCtrlRptBuf."Amount 3" += VATCtrlRptLn.Amount;
                        end;
                end;

                OnBeforeModifyVATCtrlReportBufferForExport(TempVATCtrlRptBuf, VATCtrlRptLn);
                TempVATCtrlRptBuf.Modify();
            until VATCtrlRptLn.Next = 0;

        if ShowMessage then
            Window.Close;
    end;

    local procedure IsMandatoryField(SectionCode: Code[20]; FieldNo: Integer): Boolean
    begin
        InitializationMandatoryFields;

        if not TempErrorBuf.Get(FieldNo) then
            exit(false);

        exit(StrPos(TempErrorBuf."Error Text", SectionCode) <> 0);
    end;

    [TryFunction]
    procedure CheckMandatoryField(FieldNo: Integer; VATControlReportLine: Record "VAT Control Report Line")
    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        case FieldNo of
            0:
                begin
                    RecRef.GetTable(VATControlReportLine);
                    Field.SetRange(Class, Field.Class::Normal);
                    Field.SetRange(TableNo, RecRef.Number);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    if Field.FindSet then
                        repeat
                            FieldRef := RecRef.Field(Field."No.");
                            if IsMandatoryField(VATControlReportLine."VAT Control Rep. Section Code", FieldRef.Number) then
                                FieldRef.TestField;
                        until Field.Next = 0;
                end;
            else
                if IsMandatoryField(VATControlReportLine."VAT Control Rep. Section Code", FieldNo) then begin
                    RecRef.GetTable(VATControlReportLine);
                    if TypeHelper.GetField(RecRef.Number, FieldNo, Field) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        if Field.Class = Field.Class::Normal then
                            FieldRef.TestField;
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CloseVATCtrlRepLine(VATCtrlRptHdr: Record "VAT Control Report Header"; NewCloseDocNo: Code[20]; NewCloseDate: Date)
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
        GetDocNoAndDate: Page "Get Doc.No and Date";
    begin
        VATCtrlRptHdr.TestField(Status, VATCtrlRptHdr.Status::Release);
        if not Confirm(CloseVATControlRepHeaderQst, true, VATCtrlRptHdr."No.") then
            exit;

        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        if VATCtrlRptLn.IsEmpty then
            Error(LinesNotExistErr, VATCtrlRptHdr."No.");
        VATCtrlRptLn.FindSet;

        if NewCloseDate = 0D then
            NewCloseDate := WorkDate;
        if NewCloseDocNo = '' then begin
            GetDocNoAndDate.SetValues(NewCloseDocNo, NewCloseDate);
            if GetDocNoAndDate.RunModal = ACTION::OK then
                GetDocNoAndDate.GetValues(NewCloseDocNo, NewCloseDate)
            else
                exit;
        end;
        if NewCloseDate = 0D then
            NewCloseDate := WorkDate;
        if NewCloseDocNo = '' then
            NewCloseDocNo := GenerateCloseDocNo(NewCloseDate);

        repeat
            VATCtrlRptLn.TestField("VAT Control Rep. Section Code");
            if VATCtrlRptLn."Closed by Document No." = '' then begin
                VATCtrlRptLn."Closed by Document No." := NewCloseDocNo;
                VATCtrlRptLn."Closed Date" := NewCloseDate;
                VATCtrlRptLn.Modify();
            end;
        until VATCtrlRptLn.Next = 0;
    end;

    local procedure GenerateCloseDocNo(CloseDate: Date): Code[20]
    begin
        if CloseDate = 0D then
            CloseDate := WorkDate;
        exit(Format(CloseDate, 0, '<Year4><Month,2><Day,2>') + '_' + Format(Time, 0, '<Hours24><Minutes,2>'));
    end;

    [Scope('OnPrem')]
    procedure ExportInternalDocCheckToExcel(VATCtrlRptHdr: Record "VAT Control Report Header"; ShowMessage: Boolean)
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
        TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary;
        TempVATCtrlRptBuf2: Record "VAT Control Report Buffer" temporary;
        TempVATCtrlRptBuf3: Record "VAT Control Report Buffer" temporary;
        TempExcelBuf: Record "Excel Buffer" temporary;
        i: Integer;
    begin
        if VATCtrlRptHdr."No." = '' then
            exit;

        TempVATCtrlRptBuf.Reset();
        TempVATCtrlRptBuf.DeleteAll();

        if ShowMessage then begin
            Window.Open(BufferCreateDialogMsg);
            Window.Update(1, VATCtrlRptHdr."No.");
        end;

        VATCtrlRptLn.SetRange("Control Report No.", VATCtrlRptHdr."No.");
        VATCtrlRptLn.SetRange("Exclude from Export", false);
        if VATCtrlRptLn.FindSet then
            repeat
                TempVATCtrlRptBuf.Reset();
                TempVATCtrlRptBuf.SetRange("VAT Control Rep. Section Code", VATCtrlRptLn."VAT Control Rep. Section Code");
                TempVATCtrlRptBuf.SetRange("VAT Registration No.", VATCtrlRptLn."VAT Registration No.");
                TempVATCtrlRptBuf.SetRange("VAT Date", VATCtrlRptLn."VAT Date");
                TempVATCtrlRptBuf.SetRange("Bill-to/Pay-to No.", VATCtrlRptLn."Bill-to/Pay-to No.");
                TempVATCtrlRptBuf.SetRange("Document No.", VATCtrlRptLn."Document No.");
                TempVATCtrlRptBuf.SetRange("VAT Bus. Posting Group", VATCtrlRptLn."VAT Bus. Posting Group");
                TempVATCtrlRptBuf.SetRange("VAT Prod. Posting Group", VATCtrlRptLn."VAT Prod. Posting Group");
                TempVATCtrlRptBuf.SetRange("VAT Rate", VATCtrlRptLn."VAT Rate");
                TempVATCtrlRptBuf.SetRange("Commodity Code", VATCtrlRptLn."Commodity Code");
                TempVATCtrlRptBuf.SetRange("Supplies Mode Code", VATCtrlRptLn."Supplies Mode Code");
                if not TempVATCtrlRptBuf.FindFirst then begin
                    TempVATCtrlRptBuf.Init();
                    TempVATCtrlRptBuf."VAT Control Rep. Section Code" := VATCtrlRptLn."VAT Control Rep. Section Code";
                    i += 1;
                    TempVATCtrlRptBuf."Line No." := i;
                    TempVATCtrlRptBuf."VAT Registration No." := VATCtrlRptLn."VAT Registration No.";
                    TempVATCtrlRptBuf."VAT Date" := VATCtrlRptLn."VAT Date";
                    TempVATCtrlRptBuf."Bill-to/Pay-to No." := VATCtrlRptLn."Bill-to/Pay-to No.";
                    TempVATCtrlRptBuf."Document No." := VATCtrlRptLn."Document No.";
                    TempVATCtrlRptBuf."VAT Bus. Posting Group" := VATCtrlRptLn."VAT Bus. Posting Group";
                    TempVATCtrlRptBuf."VAT Prod. Posting Group" := VATCtrlRptLn."VAT Prod. Posting Group";
                    TempVATCtrlRptBuf."VAT Rate" := VATCtrlRptLn."VAT Rate";
                    TempVATCtrlRptBuf."Commodity Code" := VATCtrlRptLn."Commodity Code";
                    TempVATCtrlRptBuf."Supplies Mode Code" := VATCtrlRptLn."Supplies Mode Code";
                    TempVATCtrlRptBuf.Insert();
                end;
                TempVATCtrlRptBuf."Total Amount" += VATCtrlRptLn.Base + VATCtrlRptLn.Amount;
                TempVATCtrlRptBuf.Modify();
            until VATCtrlRptLn.Next = 0;

        TempVATCtrlRptBuf.Reset();
        if TempVATCtrlRptBuf.FindFirst then
            repeat
                TempVATCtrlRptBuf2 := TempVATCtrlRptBuf;
                TempVATCtrlRptBuf.SetRange("VAT Control Rep. Section Code", TempVATCtrlRptBuf2."VAT Control Rep. Section Code");
                TempVATCtrlRptBuf.SetRange("VAT Registration No.", TempVATCtrlRptBuf2."VAT Registration No.");
                TempVATCtrlRptBuf.SetFilter("Document No.", '<>%1', TempVATCtrlRptBuf2."Document No.");
                TempVATCtrlRptBuf.SetFilter("Total Amount", '%1', -TempVATCtrlRptBuf2."Total Amount");
                if TempVATCtrlRptBuf.FindFirst then begin
                    TempVATCtrlRptBuf3 := TempVATCtrlRptBuf2;
                    TempVATCtrlRptBuf3."External Document No." := TempVATCtrlRptBuf."Document No.";
                    TempVATCtrlRptBuf3."Total Base" := TempVATCtrlRptBuf."Total Amount";
                    TempVATCtrlRptBuf3.Insert();

                    TempVATCtrlRptBuf.Delete();
                end;
                TempVATCtrlRptBuf := TempVATCtrlRptBuf2;
                TempVATCtrlRptBuf.Delete();

                TempVATCtrlRptBuf.Reset();
            until not TempVATCtrlRptBuf.FindFirst;

        TempVATCtrlRptBuf3.Reset();
        if TempVATCtrlRptBuf3.FindSet then begin
            i := 1;
            AddToExcelBuffer(TempExcelBuf, i, 1, TempVATCtrlRptBuf.FieldCaption("Bill-to/Pay-to No."));
            AddToExcelBuffer(TempExcelBuf, i, 2, TempVATCtrlRptBuf.FieldCaption("VAT Registration No."));
            AddToExcelBuffer(TempExcelBuf, i, 3, TempVATCtrlRptBuf.FieldCaption("Document No."));
            AddToExcelBuffer(TempExcelBuf, i, 4, TempVATCtrlRptBuf.FieldCaption("Document No.") + ' 2');
            AddToExcelBuffer(TempExcelBuf, i, 5, AmountTxt);
            AddToExcelBuffer(TempExcelBuf, i, 6, AmountTxt + ' 2');
            repeat
                i += 1;
                AddToExcelBuffer(TempExcelBuf, i, 1, TempVATCtrlRptBuf3."Bill-to/Pay-to No.");
                AddToExcelBuffer(TempExcelBuf, i, 2, TempVATCtrlRptBuf3."VAT Registration No.");
                AddToExcelBuffer(TempExcelBuf, i, 3, TempVATCtrlRptBuf3."Document No.");
                AddToExcelBuffer(TempExcelBuf, i, 4, TempVATCtrlRptBuf3."External Document No.");
                AddToExcelBuffer(TempExcelBuf, i, 5, Format(TempVATCtrlRptBuf3."Total Amount"));
                AddToExcelBuffer(TempExcelBuf, i, 6, Format(TempVATCtrlRptBuf3."Total Base"));
            until TempVATCtrlRptBuf3.Next = 0;
            TempExcelBuf.CreateBook('', 'KH1');
            TempExcelBuf.WriteSheet(
              PadStr(StrSubstNo('%1 %2', VATCtrlRptHdr."No.", VATCtrlRptHdr.Description), 30),
              CompanyName,
              UserId);
            TempExcelBuf.CloseBook;
            TempExcelBuf.SetFriendlyFilename(StrSubstNo('%1-%2', VATCtrlRptHdr."No.", VATCtrlRptHdr.Description));
            TempExcelBuf.OpenExcel;
        end else
            Message(InternalDocCheckMsg, VATCtrlRptHdr."No.");

        if ShowMessage then
            Window.Close;
    end;

    local procedure SetVATEntryFilters(var VATEntry: Record "VAT Entry"; VATStatementLine: Record "VAT Statement Line"; VATCtrlRptHdr: Record "VAT Control Report Header"; StartDate: Date; EndDate: Date)
    begin
        VATEntry.SetRange(Type, VATStatementLine."Gen. Posting Type");
        VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATStatementLine."VAT Prod. Posting Group");
        VATEntry.SetRange("Tax Jurisdiction Code", VATStatementLine."Tax Jurisdiction Code");
        VATEntry.SetRange("Use Tax", VATStatementLine."Use Tax");
        VATEntry.SetRange(Reversed, false);
        if VATStatementLine."Gen. Bus. Posting Group" <> '' then
            VATEntry.SetRange("Gen. Bus. Posting Group", VATStatementLine."Gen. Bus. Posting Group");
        if VATStatementLine."Gen. Prod. Posting Group" <> '' then
            VATEntry.SetRange("Gen. Prod. Posting Group", VATStatementLine."Gen. Prod. Posting Group");
        VATEntry.SetRange("EU 3-Party Trade");
        case VATStatementLine."EU-3 Party Trade" of
            VATStatementLine."EU-3 Party Trade"::Yes:
                VATEntry.SetRange("EU 3-Party Trade", true);
            VATStatementLine."EU-3 Party Trade"::No:
                VATEntry.SetRange("EU 3-Party Trade", false);
        end;
        VATEntry.SetRange("EU 3-Party Intermediate Role");
        case VATStatementLine."EU 3-Party Intermediate Role" of
            VATStatementLine."EU 3-Party Intermediate Role"::Yes:
                VATEntry.SetRange("EU 3-Party Intermediate Role", true);
            VATStatementLine."EU 3-Party Intermediate Role"::No:
                VATEntry.SetRange("EU 3-Party Intermediate Role", false);
        end;
        if GLSetup."Use VAT Date" then
            VATEntry.SetRange("VAT Date", StartDate, EndDate)
        else
            VATEntry.SetRange("Posting Date", StartDate, EndDate);
        if VATCtrlRptHdr."Perform. Country/Region Code" <> '' then
            VATEntry.SetRange("Perform. Country/Region Code", VATCtrlRptHdr."Perform. Country/Region Code")
        else
            VATEntry.SetRange("Perform. Country/Region Code", '');
        OnAfterSetVATEntryFilters(VATEntry, VATStatementLine, VATCtrlRptHdr);
    end;

    [Scope('OnPrem')]
    procedure CopyBufferToLine(TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary; var VATCtrlRptLn: Record "VAT Control Report Line")
    begin
        with TempVATCtrlRptBuf do begin
            VATCtrlRptLn."VAT Control Rep. Section Code" := "VAT Control Rep. Section Code";
            VATCtrlRptLn."Posting Date" := "Posting Date";
            VATCtrlRptLn."VAT Date" := "VAT Date";
            VATCtrlRptLn."Original Document VAT Date" := "Original Document VAT Date";
            VATCtrlRptLn."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
            VATCtrlRptLn."VAT Registration No." := "VAT Registration No.";
            VATCtrlRptLn."Registration No." := "Registration No.";
            VATCtrlRptLn."Tax Registration No." := "Tax Registration No.";
            VATCtrlRptLn."Document No." := CopyStr("Document No.", 1, MaxStrLen(VATCtrlRptLn."Document No."));
            VATCtrlRptLn."External Document No." := "External Document No.";
            VATCtrlRptLn.Type := Type;
            VATCtrlRptLn."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            VATCtrlRptLn."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            VATCtrlRptLn.Base := Round("Total Base", 0.01);
            VATCtrlRptLn.Amount := Round("Total Amount", 0.01);
            VATCtrlRptLn."VAT Rate" := "VAT Rate";
            VATCtrlRptLn."Commodity Code" := "Commodity Code";
            VATCtrlRptLn."Supplies Mode Code" := "Supplies Mode Code";
            VATCtrlRptLn."Corrections for Bad Receivable" := "Corrections for Bad Receivable";
            VATCtrlRptLn."Ratio Use" := "Ratio Use";
            OnAfterCopyBufferToLine(TempVATCtrlRptBuf, VATCtrlRptLn);
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyLineToBuffer(VATCtrlRptLn: Record "VAT Control Report Line"; var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary)
    var
        VATCtrlRptSection: Record "VAT Control Report Section";
    begin
        with VATCtrlRptLn do begin
            TempVATCtrlRptBuf.Init();
            TempVATCtrlRptBuf."VAT Control Rep. Section Code" := "VAT Control Rep. Section Code";
            TempVATCtrlRptBuf."Line No." := "Line No.";
            TempVATCtrlRptBuf."Posting Date" := "Posting Date";
            TempVATCtrlRptBuf."VAT Date" := "VAT Date";
            TempVATCtrlRptBuf."Original Document VAT Date" := "Original Document VAT Date";
            TempVATCtrlRptBuf."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
            TempVATCtrlRptBuf."VAT Registration No." := "VAT Registration No.";
            TempVATCtrlRptBuf."Registration No." := "Registration No.";
            TempVATCtrlRptBuf."Tax Registration No." := "Tax Registration No.";
            TempVATCtrlRptBuf.Type := Type;
            TempVATCtrlRptBuf."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            TempVATCtrlRptBuf."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
            TempVATCtrlRptBuf."VAT Rate" := "VAT Rate";
            TempVATCtrlRptBuf."Commodity Code" := "Commodity Code";
            TempVATCtrlRptBuf."Supplies Mode Code" := "Supplies Mode Code";
            TempVATCtrlRptBuf."Corrections for Bad Receivable" := "Corrections for Bad Receivable";
            TempVATCtrlRptBuf."Ratio Use" := "Ratio Use";
            TempVATCtrlRptBuf.Name := Name;
            TempVATCtrlRptBuf."Birth Date" := "Birth Date";
            TempVATCtrlRptBuf."Place of stay" := "Place of stay";

            if TempVATCtrlRptBuf."Original Document VAT Date" = 0D then
                TempVATCtrlRptBuf."Original Document VAT Date" := TempVATCtrlRptBuf."VAT Date";

            if (TempVATCtrlRptBuf."VAT Registration No." = '') and
               (TempVATCtrlRptBuf."VAT Control Rep. Section Code" = 'A4')
            then
                TempVATCtrlRptBuf."VAT Registration No." := TempVATCtrlRptBuf."Tax Registration No.";

            VATCtrlRptSection.Get("VAT Control Rep. Section Code");
            case VATCtrlRptSection."Group By" of
                VATCtrlRptSection."Group By"::"Document No.":
                    begin
                        TempVATCtrlRptBuf."Document No." := "Document No.";
                        TempVATCtrlRptBuf."External Document No." := "Document No.";
                    end;
                VATCtrlRptSection."Group By"::"External Document No.":
                    begin
                        TempVATCtrlRptBuf."Document No." := "External Document No.";
                        TempVATCtrlRptBuf."External Document No." := "External Document No.";
                    end;
                VATCtrlRptSection."Group By"::"Section Code":
                    begin
                        TempVATCtrlRptBuf."Document No." := "Document No.";
                        TempVATCtrlRptBuf."External Document No." := "External Document No.";
                    end;
            end;

            OnAfterCopyLineToBuffer(VATCtrlRptLn, TempVATCtrlRptBuf);
        end;
    end;

    local procedure AddToExcelBuffer(var TempExcelBuf: Record "Excel Buffer" temporary; RowNo: Integer; ColumnNo: Integer; Value: Text[250])
    begin
        TempExcelBuf.Validate("Row No.", RowNo);
        TempExcelBuf.Validate("Column No.", ColumnNo);
        TempExcelBuf."Cell Value as Text" := Value;
        TempExcelBuf.Insert();
    end;

    local procedure InitializationMandatoryFields()
    var
        VATCtrlRptLn: Record "VAT Control Report Line";
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        ClearMandatoryFields;

        with VATCtrlRptLn do begin
            AddMandatoryFieldToBuffer(FieldNo("VAT Registration No."), 'A1,A2,A3,A4,B1,B2');
            AddMandatoryFieldToBuffer(FieldNo("Document No."), 'A1,A2,A3,A4,B1,B2');
            AddMandatoryFieldToBuffer(FieldNo("Posting Date"), 'A1,A2,A3,A4,B1,B2');
            AddMandatoryFieldToBuffer(FieldNo(Base), 'A1,A2,A3,A4,A5,B1,B2,B3');
            AddMandatoryFieldToBuffer(FieldNo("Commodity Code"), 'A1,B1');
            AddMandatoryFieldToBuffer(FieldNo(Amount), 'A2,A4,A5,B2,B3');
            AddMandatoryFieldToBuffer(FieldNo("VAT Rate"), 'A2,A4,A5,B2,B3');
            AddMandatoryFieldToBuffer(FieldNo(Name), 'A3');
            AddMandatoryFieldToBuffer(FieldNo("Birth Date"), 'A3');
            AddMandatoryFieldToBuffer(FieldNo("Place of stay"), 'A3');
        end;
    end;

    local procedure AddMandatoryFieldToBuffer(FieldNo: Integer; SectionCodes: Text[250])
    begin
        TempErrorBuf.Init();
        TempErrorBuf."Error No." := FieldNo;
        TempErrorBuf."Error Text" := SectionCodes;
        TempErrorBuf.Insert();
    end;

    local procedure ClearMandatoryFields()
    begin
        TempErrorBuf.Reset();
        TempErrorBuf.DeleteAll();
    end;

    local procedure GetVATEntryBufferForPeriod(var TempVATEntry: Record "VAT Entry" temporary; StartDate: Date; EndDate: Date; PerformCountryRegionCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntryBufferExist(TempVATEntry) then
            exit;

        DeleteVATEntryBuffer(TempVATEntry);

        if GLSetup."Use VAT Date" then
            VATEntry.SetRange("VAT Date", StartDate, EndDate)
        else
            VATEntry.SetRange("Posting Date", StartDate, EndDate);
        if VATEntry.FindSet(false, false) then
            repeat
                TempVATEntry.Init();
                TempVATEntry := VATEntry;
                if TempVATEntry."Pmt.Disc. Tax Corr.Doc. No." <> '' then
                    TempVATEntry."Document No." := TempVATEntry."Pmt.Disc. Tax Corr.Doc. No.";
                if (PerformCountryRegionCode <> '') and (PerformCountryRegionCode = VATEntry."Perform. Country/Region Code") then
                    ExchangeAmount(TempVATEntry);
                TempVATEntry.Insert();
            until VATEntry.Next = 0;
    end;

    local procedure GetVATEntryBufferForVATStatementLine(var TempVATEntry: Record "VAT Entry" temporary; VATStatementLine: Record "VAT Statement Line"; VATCtrlRptHdr: Record "VAT Control Report Header"; StartDate: Date; EndDate: Date)
    var
        TempVATEntryGlobalCopy: Record "VAT Entry" temporary;
    begin
        DeleteVATEntryBuffer(TempVATEntry);

        GetVATEntryBufferForPeriod(TempVATEntryGlobal, StartDate, EndDate, VATCtrlRptHdr."Perform. Country/Region Code");

        TempVATEntryGlobalCopy.Copy(TempVATEntryGlobal, true);
        TempVATEntryGlobalCopy.Reset();
        SetVATEntryFilters(TempVATEntryGlobalCopy, VATStatementLine, VATCtrlRptHdr, StartDate, EndDate);
        TempVATEntryGlobalCopy.SetAutoCalcFields("VAT Control Report Line No.");
        if TempVATEntryGlobalCopy.FindSet then
            repeat
                if not SkipVATEntry(TempVATEntryGlobalCopy) then begin
                    TempVATEntry.Init();
                    TempVATEntry := TempVATEntryGlobalCopy;
                    TempVATEntry.Insert();
                end;
            until TempVATEntryGlobalCopy.Next = 0;
    end;

    local procedure DeleteVATEntryBuffer(var TempVATEntry: Record "VAT Entry" temporary)
    begin
        TempVATEntry.Reset();
        TempVATEntry.DeleteAll();
    end;

    local procedure VATEntryBufferExist(var TempVATEntry: Record "VAT Entry" temporary): Boolean
    begin
        TempVATEntry.Reset();
        exit(TempVATEntry.Count <> 0);
    end;

    [Scope('OnPrem')]
    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)', '15.3')]
    procedure ExchangeAmount(var VATEntry: Record "VAT Entry")
    var
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
    begin
        with VATEntry do begin
            if Base <> 0 then
                Base :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    Base * "Currency Factor");

            if "Advance Base" <> 0 then
                "Advance Base" :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    "Advance Base" * "Currency Factor");

            if Amount <> 0 then
                Amount :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    Amount * "Currency Factor");

            if "VAT Amount (Non Deductible)" <> 0 then
                "VAT Amount (Non Deductible)" :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    "VAT Amount (Non Deductible)" * "Currency Factor");

            if "Unrealized Amount" <> 0 then
                "Unrealized Amount" :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    "Unrealized Amount" * "Currency Factor");

            if "Unrealized Base" <> 0 then
                "Unrealized Base" :=
                  PerfCountryCurrExchRate.ExchangeAmount(
                    "Posting Date",
                    "Perform. Country/Region Code",
                    "Currency Code",
                    "Unrealized Base" * "Currency Factor");
        end;
    end;

    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)', '15.3')]
    local procedure PerfCurrExchangeAmount(SrcAmount: Decimal; SrcDate: Date; SrcCurrencyCode: Code[10]): Decimal
    var
        RegistrationCountryRegion: Record "Registration Country/Region";
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
    begin
        RegistrationCountryRegion.Get(RegistrationCountryRegion."Account Type"::"Company Information", '', PerformCountryRegionCode);
        exit(
          PerfCountryCurrExchRate.ExchangeAmount(
            SrcDate,
            RegistrationCountryRegion."Currency Code (Local)",
            SrcCurrencyCode,
            SrcAmount));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVATEntryFilters(var VATEntry: Record "VAT Entry"; VATStatementLine: Record "VAT Statement Line"; VATControlReportHeader: Record "VAT Control Report Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBufferToLine(TempVATControlReportBuffer: Record "VAT Control Report Buffer" temporary; var VATControlReportLine: Record "VAT Control Report Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyLineToBuffer(VATControlReportLine: Record "VAT Control Report Line"; var TempVATControlReportBuffer: Record "VAT Control Report Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyVATCtrlReportBufferForStatistics(var TempVATControlReportBuffer: Record "VAT Control Report Buffer" temporary; VATControlReportLine: Record "VAT Control Report Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyVATCtrlReportBufferForExport(var TempVATControlReportBuffer: Record "VAT Control Report Buffer" temporary; VATControlReportLine: Record "VAT Control Report Line")
    begin
    end;
}


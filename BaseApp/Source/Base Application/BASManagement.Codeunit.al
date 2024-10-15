codeunit 11601 "BAS Management"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASCalcEntry: Record "BAS Calc. Sheet Entry";
        GLSetup: Record "General Ledger Setup";
        BASBusUnits: Record "BAS Business Unit";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        CompanyInfo: Record "Company Information";
        BASXMLFieldID: Record "BAS XML Field ID";
        TempBASXMLFieldID: Record "BAS XML Field ID" temporary;
        BASUpdate: Report "BAS-Update";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        XMLNodeLast: DotNet XmlNode;
        Window: Dialog;
        LineNo: Integer;
        BASAdjmtSet: Boolean;
        AdjmtSet: Boolean;
        Text1450000: Label 'Please select a file to import.';
        Text1450002: Label 'This BAS has already been imported. Do you want to import a new version?';
        Text1450003: Label 'Please select a file to export.';
        Text1450004: Label 'This BAS has already been exported. Do you want to export it again?';
        Text1450005: Label 'Version %1 of BAS %2 has already been exported. Do you wish to continue?';
        Text1450006: Label 'The BAS has not been updated. Please run the update function.';
        Text1450007: Label 'BAS %1 version %2 in %3 company does not exist.';
        Text1450008: Label 'Updating G/L Entries:\\';
        Text1450009: Label 'Company Name      #1####################\';
        Text1450010: Label 'Entry             #2############';
        Text1450012: Label 'Select the Group BAS';
        Text1450013: Label 'No BAS Business Unit has been defined.';
        Text1450011: Label 'BAS Business Unit %1 has already been consolidated.';
        Text1450022: Label 'BAS %1 version %2 in %3 company does not exist.';
        Text1450023: Label 'BAS %1 version %2 in %3 company has not been updated.';
        Text1450024: Label 'Field BAS GST Division Factor in table General Ledger Setup should have same value in subsidiary company %1 and consolidating company %2.';
        Text1450025: Label 'BAS subsidiaries have been consolidated successfully into BAS %1 version %2.';
        Text1450026: Label 'Field No. %1  is system calculated or user entered field.';
        Text1450027: Label 'This BAS Calculation Sheet has been exported. It cannot be updated.';
        Text1450028: Label 'Default BAS Setup';
        Text1450029: Label 'DEFAULT';

    [Scope('OnPrem')]
    procedure ImportBAS(var BASCalcSheet1: Record "BAS Calculation Sheet"; BASFileName: Text)
    var
        FileManagement: Codeunit "File Management";
        BASFile: File;
        BlobOutStream: OutStream;
        FileInStream: InStream;
    begin
        if BASFileName = '' then
            Error(Text1450000);

        with BASCalcSheet1 do begin
            LoadXMLFile(BASFileName);
            LoadXMLNodesInTempTable;

            GLSetup.Get();
            GLSetup.TestField("BAS GST Division Factor");

            Init;
            A1 := ReadXMLNodeValues(FieldNo(A1));
            BASCalcSheet.LockTable();
            BASCalcSheet.SetRange(A1, A1);
            if BASCalcSheet.FindLast then begin
                if not Confirm(Text1450002, false) then
                    exit;
                "BAS Version" := BASCalcSheet."BAS Version" + 1;
            end else
                "BAS Version" := 1;

            A2 := ReadXMLNodeValues(FieldNo(A2));
            A2a := ReadXMLNodeValues(FieldNo(A2a));
            CompanyInfo.Get();
            TestField(A2, CompanyInfo.ABN);
            if A2a <> '' then
                TestField(A2a, CompanyInfo."ABN Division Part No.");

            Evaluate(A3, ReadXMLNodeValues(FieldNo(A3)));
            Evaluate(A4, ReadXMLNodeValues(FieldNo(A4)));
            Evaluate(A5, ReadXMLNodeValues(FieldNo(A5)));
            Evaluate(A6, ReadXMLNodeValues(FieldNo(A6)));
            Evaluate(F1, ReadXMLNodeValues(FieldNo(F1)));
            Evaluate(T2, ReadXMLNodeValues(FieldNo(T2)));
            "BAS GST Division Factor" := GLSetup."BAS GST Division Factor";
            "File Name" := CopyStr(FileManagement.GetFileName(BASFileName), 1, MaxStrLen("File Name"));
            "User Id" := UserId;
            "BAS Setup Name" := Text1450029;
            FileManagement.IsAllowedPath(BASFileName, false);
            if not FILE.Exists(BASFileName) then
                exit;
            BASFile.Open(BASFileName);
            BASFile.CreateInStream(FileInStream);
            "BAS Template XML File".CreateOutStream(BlobOutStream);
            CopyStream(BlobOutStream, FileInStream);
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportBAS(var BASCalcSheet2: Record "BAS Calculation Sheet")
    var
        BASCalcSheetSubsid: Record "BAS Calculation Sheet";
        ToFile: Text;
        BASFileName: Text;
    begin
        with BASCalcSheet2 do begin
            ToFile := "File Name";

            BASFileName := SaveBASTemplateToServerFile(A1, "BAS Version");
            if BASFileName = '' then
                Error(Text1450003);
            if Exported then
                if not Confirm(Text1450004, false) then
                    exit;
            GLSetup.Get();
            if GLSetup."BAS Group Company" then
                TestField(Consolidated, true);
            if GLSetup."BAS Group Company" then
                TestField("Group Consolidated", true);

            CheckBASCalcSheetExported(A1, "BAS Version");

            if not Updated then
                Error(Text1450006);

            LoadXMLFile(BASFileName);
            LoadXMLNodesInTempTable;

            TestField(A1, ReadXMLNodeValues(FieldNo(A1)));

            UpdateXMLNodeValues(FieldNo(T2), Format(Abs(T2)));
            UpdateXMLNodeValues(FieldNo(T3), Format(Abs(T3)));
            UpdateXMLNodeValues(FieldNo(F2), Format(Abs(F2)));
            UpdateXMLNodeValues(FieldNo(T4), T4);
            UpdateXMLNodeValues(FieldNo(F1), Format(Abs(F1)));
            UpdateXMLNodeValues(FieldNo(F4), F4);
            UpdateXMLNodeValues(FieldNo(G22), Format(Abs(G22)));
            UpdateXMLNodeValues(FieldNo(G24), G24);
            UpdateXMLNodeValues(FieldNo("1H"), Format(Abs("1H")));
            UpdateXMLNodeValues(FieldNo(T8), Format(Abs(T8)));
            UpdateXMLNodeValues(FieldNo(T9), Format(Abs(T9)));
            UpdateXMLNodeValues(FieldNo("1A"), Format(Abs("1A")));
            UpdateXMLNodeValues(FieldNo("1C"), Format(Abs("1C")));
            UpdateXMLNodeValues(FieldNo("1E"), Format(Abs("1E")));
            UpdateXMLNodeValues(FieldNo("4"), Format(Abs("4")));
            UpdateXMLNodeValues(FieldNo("1B"), Format(Abs("1B")));
            UpdateXMLNodeValues(FieldNo("1D"), Format(Abs("1D")));
            UpdateXMLNodeValues(FieldNo("1F"), Format(Abs("1F")));
            UpdateXMLNodeValues(FieldNo("1G"), Format(Abs("1G")));
            UpdateXMLNodeValues(FieldNo("5B"), Format(Abs("5B")));
            UpdateXMLNodeValues(FieldNo("6B"), Format(Abs("6B")));
            UpdateXMLNodeValues(FieldNo("7C"), Format(Abs("7C")));
            UpdateXMLNodeValues(FieldNo("7D"), Format(Abs("7D")));
            UpdateXMLNodeValues(FieldNo(G1), Format(Abs(G1)));
            UpdateXMLNodeValues(FieldNo(G2), Format(Abs(G2)));
            UpdateXMLNodeValues(FieldNo(G3), Format(Abs(G3)));
            UpdateXMLNodeValues(FieldNo(G4), Format(Abs(G4)));
            UpdateXMLNodeValues(FieldNo(G7), Format(Abs(G7)));
            UpdateXMLNodeValues(FieldNo(W1), Format(Abs(W1)));
            UpdateXMLNodeValues(FieldNo(W2), Format(Abs(W2)));
            UpdateXMLNodeValues(FieldNo(T1), Format(Abs(T1)));
            UpdateXMLNodeValues(FieldNo(G10), Format(Abs(G10)));
            UpdateXMLNodeValues(FieldNo(G11), Format(Abs(G11)));
            UpdateXMLNodeValues(FieldNo(G13), Format(Abs(G13)));
            UpdateXMLNodeValues(FieldNo(G14), Format(Abs(G14)));
            UpdateXMLNodeValues(FieldNo(G15), Format(Abs(G15)));
            UpdateXMLNodeValues(FieldNo(G18), Format(Abs(G18)));
            UpdateXMLNodeValues(FieldNo(W3), Format(Abs(W3)));
            UpdateXMLNodeValues(FieldNo(W4), Format(Abs(W4)));

            "User Id" := UserId;
            "Date of Export" := Today;
            "Time of Export" := Time;
            Exported := true;
            Modify;

            if "Group Consolidated" then begin
                BASBusUnits.FindSet();
                repeat
                    BASCalcSheetSubsid.ChangeCompany(BASBusUnits."Company Name");
                    if not BASCalcSheetSubsid.Get(BASBusUnits."Document No.", BASBusUnits."BAS Version") then
                        Error(Text1450007, BASBusUnits."Document No.", BASBusUnits."BAS Version", BASBusUnits."Company Name");
                    BASCalcSheetSubsid.Exported := true;
                    BASCalcSheetSubsid.Modify();
                until BASBusUnits.Next() = 0;
            end;

            BASCalcEntry.Reset();
            if GLSetup."BAS Group Company" then begin
                BASCalcEntry.SetCurrentKey("Consol. BAS Doc. No.", "Consol. Version No.");
                BASCalcEntry.SetRange("Consol. BAS Doc. No.", A1);
                BASCalcEntry.SetRange("Consol. Version No.", "BAS Version");
            end else begin
                BASCalcEntry.SetRange("Company Name", CompanyName);
                BASCalcEntry.SetRange("BAS Document No.", A1);
                BASCalcEntry.SetRange("BAS Version", "BAS Version");
            end;

            if BASCalcEntry.FindSet then begin
                Window.Open(Text1450008 + Text1450009 + Text1450010);
                repeat
                    GLEntry.ChangeCompany(BASCalcEntry."Company Name");
                    VATEntry.ChangeCompany(BASCalcEntry."Company Name");
                    Window.Update(1, BASCalcEntry."Company Name");
                    case BASCalcEntry.Type of
                        BASCalcEntry.Type::"G/L Entry":
                            begin
                                GLEntry.Get(BASCalcEntry."Entry No.");
                                Window.Update(2, StrSubstNo('%1: %2', BASCalcEntry.Type, GLEntry."Entry No."));
                                GLEntry."BAS Doc. No." := BASCalcEntry."BAS Document No.";
                                GLEntry."BAS Version" := BASCalcEntry."BAS Version";
                                GLEntry."Consol. BAS Doc. No." := BASCalcEntry."Consol. BAS Doc. No.";
                                GLEntry."Consol. Version No." := BASCalcEntry."Consol. Version No.";
                                GLEntry.Modify();
                            end;
                        BASCalcEntry.Type::"GST Entry":
                            begin
                                VATEntry.Get(BASCalcEntry."Entry No.");
                                Window.Update(2, StrSubstNo('%1: %2', BASCalcEntry.Type, VATEntry."Entry No."));
                                VATEntry."BAS Doc. No." := BASCalcEntry."BAS Document No.";
                                VATEntry."BAS Version" := BASCalcEntry."BAS Version";
                                VATEntry."Consol. BAS Doc. No." := BASCalcEntry."Consol. BAS Doc. No.";
                                VATEntry."Consol. Version No." := BASCalcEntry."Consol. Version No.";
                                VATEntry.Modify();
                            end;
                    end;
                until BASCalcEntry.Next() = 0;
            end;
        end;
        DownloadBASToClient(XMLDocument, ToFile);
    end;

    [Scope('OnPrem')]
    procedure UpdateBAS(var BASCalcSheet3: Record "BAS Calculation Sheet")
    begin
        with BASCalcSheet3 do begin
            if Exported then
                Error(Text1450027);
            Clear(BASUpdate);
            BASUpdate.InitializeRequest(BASCalcSheet3, true, 0, 0, false);
            BASUpdate.RunModal;
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportSubsidiaries()
    var
        BASCalcSheetConsol: Record "BAS Calculation Sheet";
        BASCalcSheetSubsid: Record "BAS Calculation Sheet";
        GLSetupSubsid: Record "General Ledger Setup";
        TempBASCalcSheet: Record "BAS Calculation Sheet";
        BASCalcScheduleList: Page "BAS Calc. Schedule List";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
        GLSetup.TestField("BAS to be Lodged as a Group", true);
        GLSetup.TestField("BAS Group Company", true);

        if not BASBusUnits.FindFirst then
            Error(Text1450013);

        BASCalcScheduleList.LookupMode(true);
        BASCalcScheduleList.Caption(Text1450012);
        if BASCalcScheduleList.RunModal <> ACTION::LookupOK then
            exit;

        BASCalcScheduleList.GetRecord(BASCalcSheetConsol);
        with TempBASCalcSheet do begin
            Init;
            A1 := BASCalcSheetConsol.A1;
            "BAS Version" := BASCalcSheetConsol."BAS Version";
            repeat
                BASBusUnits.TestField("Document No.");
                BASBusUnits.TestField("BAS Version");
                BASCalcSheetSubsid.ChangeCompany(BASBusUnits."Company Name");
                if not BASCalcSheetSubsid.Get(BASBusUnits."Document No.", BASBusUnits."BAS Version") then
                    Error(
                      Text1450022,
                      BASBusUnits."Document No.",
                      BASBusUnits."BAS Version",
                      BASBusUnits."Company Name");
                if not BASCalcSheetSubsid.Updated then
                    Error(
                      Text1450023,
                      BASBusUnits."Document No.",
                      BASBusUnits."BAS Version",
                      BASBusUnits."Company Name");
                GLSetupSubsid.ChangeCompany(BASBusUnits."Company Name");
                GLSetupSubsid.Get();
                if GLSetupSubsid."BAS GST Division Factor" <> GLSetup."BAS GST Division Factor" then
                    Error(
                      Text1450024,
                      BASBusUnits."Company Name",
                      CompanyName);

                T3 += BASCalcSheetSubsid.T3;
                T8 += BASCalcSheetSubsid.T8;
                T9 += BASCalcSheetSubsid.T9;
                F2 += BASCalcSheetSubsid.F2;
                G22 += BASCalcSheetSubsid.G22;
                "1H" += BASCalcSheetSubsid."1H";
                "1A" += BASCalcSheetSubsid."1A";
                "1C" += BASCalcSheetSubsid."1C";
                "1E" += BASCalcSheetSubsid."1E";
                "4" += BASCalcSheetSubsid."4";
                "1B" += BASCalcSheetSubsid."1B";
                "1D" += BASCalcSheetSubsid."1D";
                "1F" += BASCalcSheetSubsid."1F";
                "1G" += BASCalcSheetSubsid."1G";
                "5B" += BASCalcSheetSubsid."5B";
                "6B" += BASCalcSheetSubsid."6B";
                "7C" += BASCalcSheetSubsid."7C";
                "7D" += BASCalcSheetSubsid."7D";
                G1 += BASCalcSheetSubsid.G1;
                G2 += BASCalcSheetSubsid.G2;
                G3 += BASCalcSheetSubsid.G3;
                G4 += BASCalcSheetSubsid.G4;
                G7 += BASCalcSheetSubsid.G7;
                W1 += BASCalcSheetSubsid.W1;
                W2 += BASCalcSheetSubsid.W2;
                T1 += BASCalcSheetSubsid.T1;
                G10 += BASCalcSheetSubsid.G10;
                G11 += BASCalcSheetSubsid.G11;
                G13 += BASCalcSheetSubsid.G13;
                G14 += BASCalcSheetSubsid.G14;
                G15 += BASCalcSheetSubsid.G15;
                G18 += BASCalcSheetSubsid.G18;
                W3 += BASCalcSheetSubsid.W3;
                W4 += BASCalcSheetSubsid.W4;

                if BASCalcSheetSubsid.Consolidated then
                    Error(Text1450011, BASBusUnits."Company Name");
                BASCalcSheetSubsid.Consolidated := true;
                BASCalcSheetSubsid.Modify();

                BASCalcEntry.Reset();
                BASCalcEntry.SetRange("Company Name", BASBusUnits."Company Name");
                BASCalcEntry.SetRange("BAS Document No.", BASCalcSheetSubsid.A1);
                BASCalcEntry.SetRange("BAS Version", BASCalcSheetSubsid."BAS Version");
                if not BASCalcEntry.IsEmpty() then begin
                    BASCalcEntry.ModifyAll("Consol. BAS Doc. No.", A1);
                    BASCalcEntry.ModifyAll("Consol. Version No.", "BAS Version");
                end;
            until BASBusUnits.Next() = 0;

            BASCalcEntry.Reset();
            BASCalcEntry.SetRange("Company Name", CompanyName);
            BASCalcEntry.SetRange("BAS Document No.", A1);
            BASCalcEntry.SetRange("BAS Version", "BAS Version");
            if not BASCalcEntry.IsEmpty() then begin
                BASCalcEntry.ModifyAll("Consol. BAS Doc. No.", A1);
                BASCalcEntry.ModifyAll("Consol. Version No.", "BAS Version");
            end;

            UpdateConsolBASCalculationSheet(TempBASCalcSheet, BASCalcSheetConsol);
            Message(Text1450025, A1, "BAS Version");
        end;
    end;

    local procedure UpdateXMLNodeValues(FieldNumber: Integer; Amount: Text[100])
    begin
        BASXMLFieldID.SetCurrentKey("Field No.");
        BASXMLFieldID.SetRange("Field No.", FieldNumber);
        if BASXMLFieldID.FindFirst then
            if TempBASXMLFieldID.Get(BASXMLFieldID."XML Field ID") then begin
                Amount := DelChr(Amount, '=', ',');
                XMLNode := XMLDocument.DocumentElement.SelectSingleNode(StrSubstNo('./%1', BASXMLFieldID."XML Field ID"));
                XMLNode.InnerText := Amount;
            end;
    end;

    local procedure ReadXMLNodeValues(FieldNumber: Integer): Text[1024]
    begin
        BASXMLFieldID.SetCurrentKey("Field No.");
        BASXMLFieldID.SetRange("Field No.", FieldNumber);
        if BASXMLFieldID.FindFirst then begin
            if TempBASXMLFieldID.Get(BASXMLFieldID."XML Field ID") then begin
                XMLNode := XMLDocument.DocumentElement.SelectSingleNode(StrSubstNo('./%1', BASXMLFieldID."XML Field ID"));
                exit(XMLNode.InnerText);
            end;
        end else
            if not (FieldNumber in [
                                    BASCalcSheet.FieldNo(A1),
                                    BASCalcSheet.FieldNo(A2),
                                    BASCalcSheet.FieldNo(A2a)])
            then
                exit('0');

        exit('');
    end;

    [Scope('OnPrem')]
    procedure LoadXMLNodesInTempTable()
    var
        FirstNode: Boolean;
    begin
        TempBASXMLFieldID.Reset();
        TempBASXMLFieldID.DeleteAll();
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;
                if not TempBASXMLFieldID.Get(XMLNode.Name) then begin
                    TempBASXMLFieldID.Init();
                    TempBASXMLFieldID."XML Field ID" := XMLNode.Name;
                    TempBASXMLFieldID.Insert();
                end;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateXMLFieldIDs(BASFileName: Text)
    var
        BASXMLFieldID: Record "BAS XML Field ID";
        FirstNode: Boolean;
    begin
        LoadXMLFile(BASFileName);
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;
                if not BASXMLFieldID.Get(XMLNode.Name) then begin
                    BASXMLFieldID.Init();
                    BASXMLFieldID."XML Field ID" := XMLNode.Name;
                    BASXMLFieldID.Insert();
                end;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateXMLFieldSetup(BASFileName: Text; BASSetupName: Code[20])
    var
        BASXMLFieldIDSetup: Record "BAS XML Field ID Setup";
        FirstNode: Boolean;
    begin
        LoadXMLFile(BASFileName);
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            if LineNo = 0 then
                LineNo := 10000;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;

                BASXMLFieldIDSetup.Reset();
                BASXMLFieldIDSetup.SetCurrentKey("XML Field ID");
                BASXMLFieldIDSetup.SetRange("Setup Name", BASSetupName);
                BASXMLFieldIDSetup.SetRange("XML Field ID", XMLNode.Name);
                if not BASXMLFieldIDSetup.FindFirst then begin
                    BASXMLFieldIDSetup.Init();
                    BASXMLFieldIDSetup."Setup Name" := BASSetupName;
                    BASXMLFieldIDSetup."XML Field ID" := XMLNode.Name;
                    BASXMLFieldIDSetup."Line No." := LineNo;
                    BASXMLFieldIDSetup.Insert();
                end;
                LineNo := LineNo + 10000;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure LoadXMLFile(BASFileName: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlReaderSettings: DotNet XmlReaderSettings;
    begin
        Clear(XMLDocument);
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings;
        XmlReaderSettings.DtdProcessing := 2; // Value of DtdProcessing.Parse has been assigned as integer because DtdProcessing has method Parse.
        XMLDOMManagement.LoadXMLDocumentFromFileWithXmlReaderSettings(BASFileName, XMLDocument, XmlReaderSettings);
    end;

    [Scope('OnPrem')]
    procedure CheckBASPeriod(DocDate: Date; InvDocDate: Date): Boolean
    var
        CompanyInfo: Record "Company Information";
        Date: Record Date;
    begin
        CompanyInfo.Get();
        if InvDocDate < 20000701D then
            exit(false);
        case CompanyInfo."Tax Period" of
            CompanyInfo."Tax Period"::Monthly:
                exit(InvDocDate < CalcDate('<D1-1M>', DocDate));
            CompanyInfo."Tax Period"::Quarterly:
                begin
                    Date.SetRange("Period Type", Date."Period Type"::Quarter);
                    Date.SetFilter("Period Start", '..%1', DocDate);
                    Date.FindLast;
                    exit(InvDocDate < Date."Period Start");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GenJnlLineVendorSetAdjmt(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        with GenJnlLine do begin
            GLSetup.Get();
            if GLSetup.GSTEnabled("Document Date") then begin
                PurchSetup.Get();
                if not AdjmtSet then begin
                    Adjustment := true;
                    AdjmtSet := Adjustment;
                end;
                if not BASAdjmtSet then begin
                    "BAS Adjustment" := CheckBASPeriod("Document Date", VendLedgEntry."Document Date");
                    BASAdjmtSet := "BAS Adjustment";
                end;
                "Adjmt. Entry No." := VendLedgEntry."Entry No.";
                if not Modify then begin
                    VendLedgEntry."Pre Adjmt. Reason Code" := VendLedgEntry."Reason Code";
                    VendLedgEntry."Reason Code" := PurchSetup."Payment Discount Reason Code";
                    VendLedgEntry.Modify();
                end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GenJnlLineCustomerSetAdjmt(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        with GenJnlLine do begin
            GLSetup.Get();
            if GLSetup.GSTEnabled("Document Date") then begin
                SalesSetup.Get();
                SalesSetup.TestField("Payment Discount Reason Code");
                if not AdjmtSet then begin
                    Adjustment := true;
                    AdjmtSet := Adjustment;
                end;
                if not BASAdjmtSet then begin
                    "BAS Adjustment" := CheckBASPeriod("Document Date", CustLedgEntry."Document Date");
                    BASAdjmtSet := "BAS Adjustment";
                end;
                "Adjmt. Entry No." := CustLedgEntry."Entry No.";
                if not Modify then;
                CustLedgEntry."Pre Adjmt. Reason Code" := CustLedgEntry."Reason Code";
                CustLedgEntry."Reason Code" := SalesSetup."Payment Discount Reason Code";
                CustLedgEntry.Modify();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure VendLedgEntryReplReasonCodes(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(VendLedgEntry."Document Date") then begin
            VendLedgEntry."Reason Code" := VendLedgEntry."Pre Adjmt. Reason Code";
            VendLedgEntry."Pre Adjmt. Reason Code" := '';
            VendLedgEntry.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CustLedgEntryReplReasonCodes(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(CustLedgEntry."Document Date") then begin
            CustLedgEntry."Reason Code" := CustLedgEntry."Pre Adjmt. Reason Code";
            CustLedgEntry."Pre Adjmt. Reason Code" := '';
            CustLedgEntry.Modify();
        end;
    end;

    procedure VendorRegistered(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(0D) then begin
            Vendor.Get(VendorNo);
            exit(Vendor.Registered);
        end;

        exit(true);
    end;

    procedure GetUnregGSTProdPostGroup(GSTBusPostGroup: Code[20]; VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PurchSetup: Record "Purchases & Payables Setup";
        GSTPostingSetup: Record "VAT Posting Setup";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("GST Prod. Posting Group");
        Vendor.Get(VendorNo);
        GSTPostingSetup.Get(GSTBusPostGroup, PurchSetup."GST Prod. Posting Group");
        if not Vendor."Foreign Vend" then
            GSTPostingSetup.TestField("VAT %", 0);
        exit(PurchSetup."GST Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure CheckBASFieldID(FieldID: Integer; DisplayErrorMessage: Boolean): Boolean
    begin
        with BASCalcSheet do begin
            if not (FieldID in [
                                FieldNo("1A") .. FieldNo("1E"),
                                FieldNo("4"),
                                FieldNo("1B") .. FieldNo("1G"),
                                FieldNo("5B"),
                                FieldNo("6B"),
                                FieldNo(G1) .. FieldNo(G4),
                                FieldNo(G7),
                                FieldNo(W1) .. FieldNo(T1),
                                FieldNo(G10) .. FieldNo(G11),
                                FieldNo(G13) .. FieldNo(G15),
                                FieldNo(G18),
                                FieldNo(W3) .. FieldNo(W4),
                                FieldNo("7C"),
                                FieldNo("7D")])
            then
                if DisplayErrorMessage then
                    Error(Text1450026, FieldID);

            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenBASSetup(var CurrentBASSetupName: Code[20]; var BASSetup2: Record "BAS Setup")
    begin
        TestBASSetupName(CurrentBASSetupName);
        BASSetup2.SetRange("Setup Name", CurrentBASSetupName);
    end;

    local procedure TestBASSetupName(var CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        if not BASSetupName.Get(CurrentBASSetupName) then
            if not BASSetupName.FindFirst then begin
                BASSetupName.Init();
                BASSetupName.Name := Text1450029;
                BASSetupName.Description := Text1450028;
                BASSetupName.Insert();
                Commit();
            end;
        CurrentBASSetupName := BASSetupName.Name;
    end;

    [Scope('OnPrem')]
    procedure CheckBASSetupName(CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        BASSetupName.Get(CurrentBASSetupName);
    end;

    [Scope('OnPrem')]
    procedure CheckBASXMLSetupName(CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS XML Field Setup Name";
    begin
        BASSetupName.Get(CurrentBASSetupName);
    end;

    [Scope('OnPrem')]
    procedure SetBASSetupName(CurrentBASSetupName: Code[20]; var BASSetup: Record "BAS Setup")
    begin
        BASSetup.SetRange("Setup Name", CurrentBASSetupName);
        if BASSetup.FindFirst then;
    end;

    [Scope('OnPrem')]
    procedure LookupBASSetupName(var CurrentBASSetupName: Code[20]; var BASSetup: Record "BAS Setup")
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        Commit();
        BASSetupName.Name := CurrentBASSetupName;
        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
            CurrentBASSetupName := BASSetupName.Name;
            SetBASSetupName(CurrentBASSetupName, BASSetup);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBASXMLSetupName(CurrentBASSetupName: Code[20]; var BASXMLFieldIDSetup: Record "BAS XML Field ID Setup")
    begin
        BASXMLFieldIDSetup.SetRange("Setup Name", CurrentBASSetupName);
        if BASXMLFieldIDSetup.FindFirst then;
    end;

    [Scope('OnPrem')]
    procedure LookupBASXMLSetupName(var CurrentBASSetupName: Code[20]; var BASSetup4: Record "BAS XML Field ID Setup")
    var
        BASSetupName: Record "BAS XML Field Setup Name";
    begin
        Commit();
        BASSetupName.Name := CurrentBASSetupName;
        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
            CurrentBASSetupName := BASSetupName.Name;
            SetBASXMLSetupName(CurrentBASSetupName, BASSetup4);
        end;
    end;

    local procedure UpdateConsolBASCalculationSheet(SourceBASCalculationSheet: Record "BAS Calculation Sheet"; var ConsolidatedBASCalculationSheet: Record "BAS Calculation Sheet")
    begin
        ConsolidatedBASCalculationSheet.Get(SourceBASCalculationSheet.A1, SourceBASCalculationSheet."BAS Version");
        with ConsolidatedBASCalculationSheet do begin
            T3 := SourceBASCalculationSheet.T3;
            T8 := SourceBASCalculationSheet.T8;
            T9 := SourceBASCalculationSheet.T9;
            F2 := SourceBASCalculationSheet.F2;
            G22 := SourceBASCalculationSheet.G22;
            "1H" := SourceBASCalculationSheet."1H";
            "1A" := SourceBASCalculationSheet."1A";
            "1C" := SourceBASCalculationSheet."1C";
            "1E" := SourceBASCalculationSheet."1E";
            "4" := SourceBASCalculationSheet."4";
            "1B" := SourceBASCalculationSheet."1B";
            "1D" := SourceBASCalculationSheet."1D";
            "1F" := SourceBASCalculationSheet."1F";
            "1G" := SourceBASCalculationSheet."1G";
            "5B" := SourceBASCalculationSheet."5B";
            "6B" := SourceBASCalculationSheet."6B";
            "7C" := SourceBASCalculationSheet."7C";
            "7D" := SourceBASCalculationSheet."7D";
            G1 := SourceBASCalculationSheet.G1;
            G2 := SourceBASCalculationSheet.G2;
            G3 := SourceBASCalculationSheet.G3;
            G4 := SourceBASCalculationSheet.G4;
            G7 := SourceBASCalculationSheet.G7;
            W1 := SourceBASCalculationSheet.W1;
            W2 := SourceBASCalculationSheet.W2;
            T1 := SourceBASCalculationSheet.T1;
            G10 := SourceBASCalculationSheet.G10;
            G11 := SourceBASCalculationSheet.G11;
            G13 := SourceBASCalculationSheet.G13;
            G14 := SourceBASCalculationSheet.G14;
            G15 := SourceBASCalculationSheet.G15;
            G18 := SourceBASCalculationSheet.G18;
            W3 := SourceBASCalculationSheet.W3;
            W4 := SourceBASCalculationSheet.W4;
            Updated := true;
            Consolidated := true;
            "Group Consolidated" := true;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveBASTemplateToServerFile(BASCalcSheetNo: Code[11]; BASVersion: Integer) FileName: Text
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        BASCalculationSheet.Get(BASCalcSheetNo, BASVersion);
        BASCalculationSheet.CalcFields("BAS Template XML File");
        TempBlob.FromRecord(BASCalculationSheet, BASCalculationSheet.FieldNo("BAS Template XML File"));

        FileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure DownloadBASToClient(XMLDocument: DotNet XmlDocument; ToFile: Text)
    var
        FileManagement: Codeunit "File Management";
        ServerFileName: Text;
    begin
        ServerFileName := FileManagement.ServerTempFileName('xml');
        XMLDocument.Save(ServerFileName);
        FileManagement.DownloadHandler(ServerFileName, '', '', '', ToFile);
    end;

    local procedure CheckBASCalcSheetExported(BASCalcSheetNo: Code[11]; BASVersionNo: Integer)
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        BASCalculationSheet.SetRange(A1, BASCalcSheetNo);
        BASCalculationSheet.SetFilter("BAS Version", '<>%1', BASVersionNo);
        BASCalculationSheet.SetRange(Exported, true);
        if BASCalculationSheet.FindLast then
            if BASCalculationSheet."BAS Version" <> BASVersionNo then
                if not Confirm(Text1450005, false, BASCalculationSheet."BAS Version", BASCalculationSheet.A1) then
                    Error('');
    end;
}


report 95 "Date Compress VAT Entries"
{
    Caption = 'Date Compress VAT Entries';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = SORTING(Type, Closed);
            RequestFilterFields = Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Jurisdiction Code", "Use Tax", Closed;

            trigger OnAfterGetRecord()
            begin
                VATEntry2 := "VAT Entry";
                with VATEntry2 do begin
                    if not
                       SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then
                        SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                    CopyFilters("VAT Entry");
                    SetRange(Type, Type);
                    SetRange(Closed, Closed);
                    SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                    SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                    SetRange("Use Tax", "Use Tax");
                    SetFilter("Posting Date", DateComprMgt.GetDateFilter("Posting Date", EntrdDateComprReg, true));
                    SetRange("Document Type", "Document Type");

                    LastVATEntryNo := LastVATEntryNo + 1;

                    NewVATEntry.Init();
                    NewVATEntry."Entry No." := LastVATEntryNo;
                    NewVATEntry.Type := Type;
                    NewVATEntry.Closed := Closed;
                    NewVATEntry."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
                    NewVATEntry."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                    NewVATEntry."Tax Jurisdiction Code" := "Tax Jurisdiction Code";
                    NewVATEntry."Use Tax" := "Use Tax";
                    NewVATEntry."Posting Date" := GetRangeMin("Posting Date");
                    NewVATEntry."Document Type" := "Document Type";
                    NewVATEntry."Source Code" := SourceCodeSetup."Compress VAT Entries";
                    NewVATEntry."User ID" := UserId;
                    NewVATEntry."Transaction No." := NextTransactionNo;
                    Window.Update(1, NewVATEntry.Type);
                    Window.Update(2, NewVATEntry."VAT Bus. Posting Group");
                    Window.Update(3, NewVATEntry."VAT Prod. Posting Group");
                    Window.Update(4, NewVATEntry."Tax Jurisdiction Code");
                    Window.Update(5, NewVATEntry."Use Tax");
                    Window.Update(6, NewVATEntry."Posting Date");
                    DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                    Window.Update(7, DateComprReg."No. of New Records");

                    if RetainNo(FieldNo("Document No.")) then begin
                        SetRange("Document No.", "Document No.");
                        NewVATEntry."Document No." := "Document No.";
                    end;
                    if RetainNo(FieldNo("Bill-to/Pay-to No.")) then begin
                        SetRange("Bill-to/Pay-to No.", "Bill-to/Pay-to No.");
                        NewVATEntry."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
                    end;
                    if RetainNo(FieldNo("EU 3-Party Trade")) then begin
                        SetRange("EU 3-Party Trade", "EU 3-Party Trade");
                        NewVATEntry."EU 3-Party Trade" := "EU 3-Party Trade";
                    end;
                    if RetainNo(FieldNo("Country/Region Code")) then begin
                        SetRange("Country/Region Code", "Country/Region Code");
                        NewVATEntry."Country/Region Code" := "Country/Region Code";
                    end;
                    if RetainNo(FieldNo("Internal Ref. No.")) then begin
                        SetRange("Internal Ref. No.", "Internal Ref. No.");
                        NewVATEntry."Internal Ref. No." := "Internal Ref. No.";
                    end;
                    if Base >= 0 then
                        SetFilter(Base, '>=0')
                    else
                        SetFilter(Base, '<0');
                    repeat
                        NewVATEntry.Base := NewVATEntry.Base + Base;
                        NewVATEntry.Amount := NewVATEntry.Amount + Amount;
                        NewVATEntry."Unrealized Amount" := NewVATEntry."Unrealized Amount" + "Unrealized Amount";
                        NewVATEntry."Unrealized Base" := NewVATEntry."Unrealized Base" + "Unrealized Base";
                        NewVATEntry."Additional-Currency Base" :=
                          NewVATEntry."Additional-Currency Base" + "Additional-Currency Base";
                        NewVATEntry."Additional-Currency Amount" :=
                          NewVATEntry."Additional-Currency Amount" + "Additional-Currency Amount";
                        NewVATEntry."Add.-Currency Unrealized Amt." :=
                          NewVATEntry."Add.-Currency Unrealized Amt." + "Add.-Currency Unrealized Amt.";
                        NewVATEntry."Add.-Currency Unrealized Base" :=
                          NewVATEntry."Add.-Currency Unrealized Base" + "Add.-Currency Unrealized Base";
                        NewVATEntry."Remaining Unrealized Amount" :=
                          NewVATEntry."Remaining Unrealized Amount" + "Remaining Unrealized Amount";
                        NewVATEntry."Remaining Unrealized Base" :=
                          NewVATEntry."Remaining Unrealized Base" + "Remaining Unrealized Base";
                        Delete;
                        GLEntryVATEntryLink.SetRange("VAT Entry No.", "Entry No.");
                        if GLEntryVATEntryLink.FindSet then
                            repeat
                                GLEntryVATEntryLink2 := GLEntryVATEntryLink;
                                GLEntryVATEntryLink2.Delete();
                                GLEntryVATEntryLink2."VAT Entry No." := NewVATEntry."Entry No.";
                                if GLEntryVATEntryLink2.Insert() then;
                            until GLEntryVATEntryLink.Next = 0;
                        DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
                        Window.Update(8, DateComprReg."No. Records Deleted");
                    until Next = 0;
                    NewVATEntry.Insert();
                end;

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(GLReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(GLReg, DateComprReg);
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                LastTransactionNo: Integer;
            begin
                if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                    CurrReport.Break();

                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008 +
                  Text009 +
                  Text010 +
                  Text011 +
                  Text012);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress VAT Entries");

                GLEntry.LockTable();
                NewVATEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastGLEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastVATEntryNo := NewVATEntry.GetLastEntryNo();
                SetRange("Entry No.", 0, LastVATEntryNo);
                SetRange("Posting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("EntrdDateComprReg.""Starting Date"""; EntrdDateComprReg."Starting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date to be included in the date compression. The compression affects all VAT entries from this date to the Ending Date field.';
                    }
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to be included in the date compression. The compression affects all VAT entries from the Starting Date field.';
                    }
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the length of the period whose entries will be combined. To see the options, choose the field.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; Retain[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies if you want to retain the contents of the Document No. field. ';
                        }
                        field("Retain[2]"; Retain[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bill-to/Pay-to No.';
                            ToolTip = 'Specifies whether you want to retain the contents of the Bill-to/Pay-to No. field. ';
                        }
                        field("Retain[3]"; Retain[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'EU 3-Party Trade';
                            ToolTip = 'Specifies if you want to retain the contents of the EU 3-Party Trade field. ';
                        }
                        field("Retain[4]"; Retain[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Country/Region Code';
                            ToolTip = 'Specifies if you want to retain the address country/region field contents.';
                        }
                        field("Retain[5]"; Retain[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Internal Ref. No.';
                            ToolTip = 'Specifies if you want to retain the contents of the Internal Ref. No. field.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := Today;

            with "VAT Entry" do begin
                InsertField(FieldNo("Document No."), FieldCaption("Document No."));
                InsertField(FieldNo("Bill-to/Pay-to No."), FieldCaption("Bill-to/Pay-to No."));
                InsertField(FieldNo("EU 3-Party Trade"), FieldCaption("EU 3-Party Trade"));
                InsertField(FieldNo("Country/Region Code"), FieldCaption("Country/Region Code"));
                InsertField(FieldNo("Internal Ref. No."), FieldCaption("Internal Ref. No."));
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        VATEntryFilter := CopyStr("VAT Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));
    end;

    var
        Text003: Label '%1 must be specified.';
        Text004: Label 'Date compressing VAT entries...\\';
        Text005: Label 'Type                     #1##########\';
        Text006: Label 'VAT Bus. Posting Group   #2##########\';
        Text007: Label 'VAT Prod. Posting Group  #3##########\';
        Text008: Label 'Tax Jurisdiction         #4##########\';
        Text009: Label 'Use Tax                  #5##########\';
        Text010: Label 'Date                     #6######\\';
        Text011: Label 'No. of new entries       #7######\';
        Text012: Label 'No. of entries deleted   #8######';
        SourceCodeSetup: Record "Source Code Setup";
        EntrdDateComprReg: Record "Date Compr. Register";
        DateComprReg: Record "Date Compr. Register";
        GLReg: Record "G/L Register";
        NewVATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        GLEntryVATEntryLink2: Record "G/L Entry - VAT Entry Link";
        DateComprMgt: Codeunit DateComprMgt;
        Window: Dialog;
        VATEntryFilter: Text[250];
        NoOfFields: Integer;
        Retain: array[10] of Boolean;
        FieldNumber: array[10] of Integer;
        FieldNameArray: array[10] of Text[100];
        LastGLEntryNo: Integer;
        LastVATEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        i: Integer;
        CompressEntriesQst: Label 'This batch job deletes entries. Therefore, it is important that you make a backup of the database before you run the batch job.\\Do you want to date compress the entries?';

    local procedure InitRegisters()
    begin
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastGLEntryNo + 1, LastVATEntryNo + 1, SourceCodeSetup."Compress Vend. Ledger", '', '');

        DateComprReg.InitRegister(
          DATABASE::"VAT Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", VATEntryFilter, GLReg."No.", SourceCodeSetup."Compress VAT Entries");
        for i := 1 to NoOfFields do
            if Retain[i] then
                DateComprReg."Retain Field Contents" :=
                  CopyStr(
                    DateComprReg."Retain Field Contents" + ',' + FieldNameArray[i], 1,
                    MaxStrLen(DateComprReg."Retain Field Contents"));
        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure InsertRegisters(var GLReg: Record "G/L Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FoundLastEntryNo: Integer;
        FoundLastVATEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastGLEntryNo := LastGLEntryNo + 1;
        GLEntry."Entry No." := LastGLEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry."Source Code" := SourceCodeSetup."Compress VAT Entries";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := UserId;
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := LastGLEntryNo;
        GLReg."To VAT Entry No." := NewVATEntry."Entry No.";

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        GLEntry.LockTable();
        NewVATEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLentry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastVATEntryNo := NewVATEntry.GetLastEntryNo();
        if (LastGLEntryNo <> FoundLastEntryNo) or
           (LastVATEntryNo <> FoundLastVATEntryNo)
        then begin
            LastGLEntryNo := FoundLastEntryNo;
            LastVATEntryNo := FoundLastVATEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters;
        end;
    end;

    local procedure InsertField(Number: Integer; Name: Text[100])
    begin
        NoOfFields := NoOfFields + 1;
        FieldNumber[NoOfFields] := Number;
        FieldNameArray[NoOfFields] := Name;
    end;

    local procedure RetainNo(Number: Integer): Boolean
    begin
        exit(Retain[Index(Number)]);
    end;

    local procedure Index(Number: Integer): Integer
    begin
        for i := 1 to NoOfFields do
            if Number = FieldNumber[i] then
                exit(i);
    end;

    local procedure InitializeParameter()
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := Today;

        with "VAT Entry" do begin
            InsertField(FieldNo("Document No."), FieldCaption("Document No."));
            InsertField(FieldNo("Bill-to/Pay-to No."), FieldCaption("Bill-to/Pay-to No."));
            InsertField(FieldNo("EU 3-Party Trade"), FieldCaption("EU 3-Party Trade"));
            InsertField(FieldNo("Country/Region Code"), FieldCaption("Country/Region Code"));
            InsertField(FieldNo("Internal Ref. No."), FieldCaption("Internal Ref. No."));
        end;
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; RetainDocumentNo: Boolean; RetainBilltoPaytoNo: Boolean; RetainEU3PartyTrade: Boolean; RetainCountryRegionCode: Boolean; RetainInternalRefNo: Boolean)
    begin
        InitializeParameter;
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        Retain[1] := RetainDocumentNo;
        Retain[2] := RetainBilltoPaytoNo;
        Retain[3] := RetainEU3PartyTrade;
        Retain[4] := RetainCountryRegionCode;
        Retain[5] := RetainInternalRefNo;
    end;
}


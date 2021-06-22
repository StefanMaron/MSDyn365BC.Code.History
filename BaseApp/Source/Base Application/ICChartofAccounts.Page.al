page 605 "IC Chart of Accounts"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Chart of Accounts';
    CardPageID = "IC G/L Account Card";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Import/Export';
    SourceTable = "IC G/L Account";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the IC general ledger account.';
                }
                field("Income/Balance"; "Income/Balance")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to G/L Acc. No."; "Map-to G/L Acc. No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the G/L account in your chart of accounts that corresponds to this intercompany G/L account.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Map to Acc. with Same No.")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Map to Acc. with Same No.';
                    Image = MapAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Map the selected intercompany G/L accounts to G/L accounts with the same number.';

                    trigger OnAction()
                    var
                        ICGLAcc: Record "IC G/L Account";
                        ICMapping: Codeunit "IC Mapping";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        CurrPage.SetSelectionFilter(ICGLAcc);
                        if ICGLAcc.Find('-') and ConfirmManagement.GetResponseOrDefault(Text000, true) then
                            repeat
                                ICMapping.MapAccounts(ICGLAcc);
                            until ICGLAcc.Next = 0;
                    end;
                }
                action("Copy from Chart of Accounts")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Copy from Chart of Accounts';
                    Image = CopyFromChartOfAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Create intercompany G/L accounts from G/L accounts.';

                    trigger OnAction()
                    begin
                        CopyFromChartOfAccounts;
                    end;
                }
                action("In&dent IC Chart of Accounts")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'In&dent IC Chart of Accounts';
                    Image = Indent;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Indent accounts between a Begin-Total and the matching End-Total one level to make the chart of accounts easier to read.';

                    trigger OnAction()
                    var
                        IndentCOA: Codeunit "G/L Account-Indent";
                    begin
                        IndentCOA.RunICAccountIndent;
                    end;
                }
                separator(Action21)
                {
                }
                action(Import)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Import an intercompany chart of accounts from a file.';

                    trigger OnAction()
                    begin
                        ImportFromXML;
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Export the intercompany chart of accounts to a file.';

                    trigger OnAction()
                    begin
                        ExportToXML;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine;
    end;

    var
        Text000: Label 'Are you sure you want to map the selected lines?';
        Text001: Label 'Select file to import into %1';
        Text002: Label 'ICGLAcc.xml';
        Text004: Label 'Are you sure you want to copy from %1?';
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;
        Text005: Label 'Enter the file name.';
        Text006: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';

    local procedure CopyFromChartOfAccounts()
    var
        GLAcc: Record "G/L Account";
        ICGLAcc: Record "IC G/L Account";
        ConfirmManagement: Codeunit "Confirm Management";
        ChartofAcc: Page "Chart of Accounts";
        ICGLAccEmpty: Boolean;
        ICGLAccExists: Boolean;
        PrevIndentation: Integer;
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, ChartofAcc.Caption), true) then
            exit;

        ICGLAccEmpty := not ICGLAcc.FindFirst;
        ICGLAcc.LockTable();
        if GLAcc.Find('-') then
            repeat
                if GLAcc."Account Type" = GLAcc."Account Type"::"End-Total" then
                    PrevIndentation := PrevIndentation - 1;
                if not ICGLAccEmpty then
                    ICGLAccExists := ICGLAcc.Get(GLAcc."No.");
                if not ICGLAccExists and not GLAcc.Blocked then begin
                    ICGLAcc.Init();
                    ICGLAcc."No." := GLAcc."No.";
                    ICGLAcc.Name := GLAcc.Name;
                    ICGLAcc."Account Type" := GLAcc."Account Type";
                    ICGLAcc."Income/Balance" := GLAcc."Income/Balance";
                    ICGLAcc.Validate(Indentation, PrevIndentation);
                    ICGLAcc.Insert();
                end;
                PrevIndentation := GLAcc.Indentation;
                if GLAcc."Account Type" = GLAcc."Account Type"::"Begin-Total" then
                    PrevIndentation := PrevIndentation + 1;
            until GLAcc.Next = 0;
    end;

    local procedure ImportFromXML()
    var
        CompanyInfo: Record "Company Information";
        ICGLAccIO: XMLport "IC G/L Account Import/Export";
        IFile: File;
        IStr: InStream;
        FileName: Text[1024];
        StartFileName: Text[1024];
    begin
        CompanyInfo.Get();

        StartFileName := CompanyInfo."IC Inbox Details";
        if StartFileName <> '' then begin
            if StartFileName[StrLen(StartFileName)] <> '\' then
                StartFileName := StartFileName + '\';
            StartFileName := StartFileName + '*.xml';
        end;

        if not Upload(StrSubstNo(Text001, TableCaption), '', Text006, StartFileName, FileName) then
            Error(Text005);

        IFile.Open(FileName);
        IFile.CreateInStream(IStr);
        ICGLAccIO.SetSource(IStr);
        ICGLAccIO.Import;
    end;

    local procedure ExportToXML()
    var
        CompanyInfo: Record "Company Information";
        FileMgt: Codeunit "File Management";
        ICGLAccIO: XMLport "IC G/L Account Import/Export";
        OFile: File;
        OStr: OutStream;
        FileName: Text;
        DefaultFileName: Text;
    begin
        CompanyInfo.Get();

        DefaultFileName := CompanyInfo."IC Inbox Details";
        if DefaultFileName <> '' then
            if DefaultFileName[StrLen(DefaultFileName)] <> '\' then
                DefaultFileName := DefaultFileName + '\';
        DefaultFileName := DefaultFileName + Text002;

        FileName := FileMgt.ServerTempFileName('xml');
        if FileName = '' then
            exit;

        OFile.Create(FileName);
        OFile.CreateOutStream(OStr);
        ICGLAccIO.SetDestination(OStr);
        ICGLAccIO.Export;
        OFile.Close;
        Clear(OStr);

        Download(FileName, 'Export', TemporaryPath, '', DefaultFileName);
    end;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
        Emphasize := "Account Type" <> "Account Type"::Posting;
    end;
}


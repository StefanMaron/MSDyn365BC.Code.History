#if not CLEAN19
page 31088 "Acc. Schedule Extensions"
{
    Caption = 'Acc. Schedule Extensions (Obsolete)';
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SaveValues = true;
    SourceTable = "Acc. Schedule Extension";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220020)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of account schedule extensions.';
                }
                field("Source Table"; Rec."Source Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the selected source table (VAT entry, Value entry, Customer or vendor entry).';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of account schedule extensions.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type of the selected document.';
                    Visible = "SrcTypeVisible";
                }
                field("Source Filter"; Rec."Source Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the source.';
                    Visible = "SrcFilterVisible";
                }
                field("G/L Account Filter"; Rec."G/L Account Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the account number.';
                    Visible = "GLAccFilterVisible";
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of location filter.';
                    Visible = "LocFilterVisible";
                }
                field("Bin Filter"; Rec."Bin Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the bin filter.';
                    Visible = "BinFilterVisible";
                }
                field("G/L Amount Type"; Rec."G/L Amount Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of G/L account type.';
                    Visible = "GLAmtTypeVisible";
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the entry.';
                    Visible = "EntryTypeVisible";
                }
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if line of sales journal is prepayment';
                    Visible = PrepaymentVisible;
                }
                field("VAT Amount Type"; Rec."VAT Amount Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the VAT amount type (Base or amount.)';
                    Visible = "VATAmtTypeVisible";
                }
                field("VAT Bus. Post. Group Filter"; Rec."VAT Bus. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the VAT business posting group.';
                    Visible = VATBusPostGroupFilterVisible;
                }
                field("VAT Prod. Post. Group Filter"; Rec."VAT Prod. Post. Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the VAT product posting group.';
                    Visible = VATProdPostGroupFilterVisible;
                }
                field("Due Date Filter"; Rec."Due Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the document''s due date.';
                    Visible = "DueDateFilterVisible";
                }
                field("Amount Sign"; Rec."Amount Sign")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount sign for the account schedule extension.';
                    Visible = "AmtSignVisible";
                }
                field("Document Type Filter"; Rec."Document Type Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies setup of documents type for filtr account schedule (invoice, payment).';
                    Visible = "DocumentTypeFilterVisible";
                }
                field("Posting Date Filter"; Rec."Posting Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the posting date.';
                    Visible = "PostingDateFilterVisible";
                }
                field("Reverse Sign"; Rec."Reverse Sign")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies reverse sign';
                    Visible = "ReverseSignVisible";
                }
                field("Posting Group Filter"; Rec."Posting Group Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies filter setup of the posting group.';
                    Visible = "PostingGrFilterVisible";
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        DocumentTypeFilterVisible := true;
        DueDateFilterVisible := true;
        PostingDateFilterVisible := true;
        PostingGrFilterVisible := true;
        BinFilterVisible := true;
        LocFilterVisible := true;
        VATProdPostGroupFilterVisible := true;
        VATBusPostGroupFilterVisible := true;
        VATAmtTypeVisible := true;
        ReverseSignVisible := true;
        PrepaymentVisible := true;
        EntryTypeVisible := true;
        AmtSignVisible := true;
        GLAmtTypeVisible := true;
        GLAccFilterVisible := true;
        SrcFilterVisible := true;
        SrcTypeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        if HiddenParameters then
            LedgEntryType := HiddenLedgEntryType;
        UpdateControls();
    end;

    var
        LedgEntryType: Option "VAT Entry","Value Entry","Customer Entry","Vendor Entry";
        HiddenLedgEntryType: Option "VAT Entry","Value Entry","Customer Entry","Vendor Entry";
        HiddenParameters: Boolean;
        [InDataSet]
        SrcTypeVisible: Boolean;
        [InDataSet]
        SrcFilterVisible: Boolean;
        [InDataSet]
        GLAccFilterVisible: Boolean;
        [InDataSet]
        GLAmtTypeVisible: Boolean;
        [InDataSet]
        AmtSignVisible: Boolean;
        [InDataSet]
        EntryTypeVisible: Boolean;
        [InDataSet]
        PrepaymentVisible: Boolean;
        [InDataSet]
        ReverseSignVisible: Boolean;
        [InDataSet]
        VATAmtTypeVisible: Boolean;
        [InDataSet]
        VATBusPostGroupFilterVisible: Boolean;
        [InDataSet]
        VATProdPostGroupFilterVisible: Boolean;
        [InDataSet]
        LocFilterVisible: Boolean;
        [InDataSet]
        BinFilterVisible: Boolean;
        [InDataSet]
        PostingGrFilterVisible: Boolean;
        [InDataSet]
        PostingDateFilterVisible: Boolean;
        [InDataSet]
        DueDateFilterVisible: Boolean;
        [InDataSet]
        DocumentTypeFilterVisible: Boolean;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        SetRange("Source Table", LedgEntryType);

        SrcTypeVisible := false;
        SrcFilterVisible := false;
        GLAccFilterVisible := false;
        GLAmtTypeVisible := false;
        AmtSignVisible := false;
        EntryTypeVisible := false;
        PrepaymentVisible := false;
        ReverseSignVisible := false;
        VATAmtTypeVisible := false;
        VATBusPostGroupFilterVisible := false;
        VATProdPostGroupFilterVisible := false;
        LocFilterVisible := false;
        BinFilterVisible := false;
        PostingGrFilterVisible := false;
        PostingDateFilterVisible := false;
        DueDateFilterVisible := false;
        DocumentTypeFilterVisible := false;

        case LedgEntryType of
            LedgEntryType::"VAT Entry":
                begin
                    EntryTypeVisible := true;
                    ReverseSignVisible := true;
                    VATAmtTypeVisible := true;
                    VATBusPostGroupFilterVisible := true;
                    VATProdPostGroupFilterVisible := true;
                end;
            LedgEntryType::"Value Entry":
                begin
                    LocFilterVisible := true;
                    ReverseSignVisible := true;
                end;
            LedgEntryType::"Customer Entry",
            LedgEntryType::"Vendor Entry":
                begin
                    PostingGrFilterVisible := true;
                    PostingDateFilterVisible := true;
                    DueDateFilterVisible := true;
                    DocumentTypeFilterVisible := true;
                    PrepaymentVisible := true;
                    AmtSignVisible := true;
                    ReverseSignVisible := true;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetLedgType(NewLedgType: Integer)
    begin
        HiddenLedgEntryType := NewLedgType;
        HiddenParameters := true;
    end;
}
#endif

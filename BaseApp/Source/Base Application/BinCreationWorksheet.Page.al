page 7372 "Bin Creation Worksheet"
{
    AccessByPermission = TableData Bin = R;
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Bin Creation Worksheet';
    DataCaptionFields = Name;
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Bin Creation Worksheet Line";
    SourceTableView = SORTING("Worksheet Template Name", Name, "Location Code", "Line No.")
                      WHERE(Type = CONST(Bin));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the bin creation worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    BinCreateLine.LookupBinCreationName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    BinCreateLine.CheckName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Location;
                Caption = 'Location Code';
                Editable = false;
                Lookup = true;
                TableRelation = Location;
                ToolTip = 'Specifies the location where the bins exist.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone where the bin on the worksheet will be located.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description for the bin that should be created.';
                }
                field("Bin Type Code"; "Bin Type Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin type or bin content that should be created.';
                    Visible = false;
                }
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Block Movement"; "Block Movement")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how the movement of a particular item, or bin content, into or out of this bin, is blocked.';
                    Visible = false;
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the special equipment code of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Bin Ranking"; "Bin Ranking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ranking of the bin or bin content that should be created.';
                    Visible = false;
                }
                field("Maximum Cubage"; "Maximum Cubage")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum cubage of the bin that should be created.';
                    Visible = false;
                }
                field("Maximum Weight"; "Maximum Weight")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the maximum weight of the bin that should be created.';
                    Visible = false;
                }
                field("Cross-Dock Bin"; "Cross-Dock Bin")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies new cross-dock bins.';
                    Visible = false;
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
                action(CalculateBins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate &Bins';
                    Ellipsis = true;
                    Image = SuggestBin;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Generate bin replenishment lines.';

                    trigger OnAction()
                    begin
                        BinCreateWksh.SetTemplAndWorksheet("Worksheet Template Name", Name, CurrentLocationCode);
                        BinCreateWksh.RunModal;
                        Clear(BinCreateWksh);
                    end;
                }
                action("&Create Bins")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Bins';
                    Image = CreateBins;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Create the bins that you have defined in the worksheet.';

                    trigger OnAction()
                    begin
                        BinCreateLine.Copy(Rec);
                        SetFilter("Bin Code", '<>%1', '');
                        CODEUNIT.Run(CODEUNIT::"Bin Create", Rec);
                        BinCreateLine.Reset();
                        Copy(BinCreateLine);
                        FilterGroup(2);
                        SetRange("Worksheet Template Name", "Worksheet Template Name");
                        SetRange(Name, Name);
                        SetRange("Location Code", CurrentLocationCode);
                        FilterGroup(0);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    BinCreateLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
                    BinCreateLine.SetRange(Name, Name);
                    BinCreateLine.SetRange("Location Code", "Location Code");
                    BinCreateLine.SetRange(Type, BinCreateLine.Type::Bin);
                    REPORT.Run(REPORT::"Bin Creation Wksh. Report", true, false, BinCreateLine);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(GetRangeMax("Worksheet Template Name"));
    end;

    trigger OnOpenPage()
    var
        WkshSelected: Boolean;
    begin
        OpenedFromBatch := (Name <> '') and ("Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Name;
            CurrentLocationCode := "Location Code";
            BinCreateLine.OpenWksh(CurrentJnlBatchName, CurrentLocationCode, Rec);
            exit;
        end;
        BinCreateLine.TemplateSelection(PAGE::"Bin Creation Worksheet", 0, Rec, WkshSelected);
        if not WkshSelected then
            Error('');
        BinCreateLine.OpenWksh(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        BinCreateWksh: Report "Calculate Bins";
        CurrentLocationCode: Code[10];
        CurrentJnlBatchName: Code[10];
        OpenedFromBatch: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        BinCreateLine.SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}


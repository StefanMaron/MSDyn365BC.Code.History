page 12479 "FA Movement Act Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "FA Document Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; "FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FA: Record "Fixed Asset";
                        FADocHeader: Record "FA Document Header";
                        FAList: Page "Fixed Asset List";
                    begin
                        FADocHeader.Get("Document Type", "Document No.");
                        FA.Reset;
                        if FADocHeader."FA Location Code" <> '' then begin
                            FA.SetCurrentKey("FA Location Code");
                            FA.FilterGroup := 2;
                            FA.SetRange("FA Location Code", FADocHeader."FA Location Code");
                            FA.FilterGroup := 0;
                        end;
                        FAList.SetTableView(FA);
                        if FA.Get("FA No.") then
                            FAList.SetRecord(FA);
                        FAList.LookupMode(true);
                        if FAList.RunModal = ACTION::LookupOK then begin
                            FAList.GetRecord(FA);
                            Validate("FA No.", FA."No.");
                        end;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field(Status; Status)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the status of the fixed asset.';
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field("New Depreciation Book Code"; "New Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an alternative depreciation book code that is used to post depreciation for the fixed asset entry.';
                }
                field("FA Employee No."; "FA Employee No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the employee number of the person who maintains possession of the fixed asset.';
                    Visible = FAEmployeeNoVisible;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of the fixed asset movement or write-off line.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        ShowComments;
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("FA Movement FA-2")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Movement FA-2';
                    ToolTip = 'View the movement of fixed assets between employees or locations, or records the current status of fixed assets, such as when an asset is repaired or when it appreciates in value. After you post an FA Movement Act, you can use this report to print the posted document.';

                    trigger OnAction()
                    var
                        FADocHeader: Record "FA Document Header";
                        FADocLine: Record "FA Document Line";
                        FAMovementActRep: Report "FA Movement FA-2";
                    begin
                        SetFilters(FADocHeader, FADocLine);
                        FAMovementActRep.SetTableView(FADocHeader);
                        FAMovementActRep.SetTableView(FADocLine);
                        FAMovementActRep.Run;
                    end;
                }
                action("FA Movement FA-3")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Movement FA-3';
                    ToolTip = 'View the reception of repaired, reconstructed, and modernized fixed assets. After you post an FA Movement Act, you can use this report to print the posted document.';

                    trigger OnAction()
                    var
                        FADocHeader: Record "FA Document Header";
                        FADocLine: Record "FA Document Line";
                        FAMovementActRep: Report "FA Movement FA-3";
                    begin
                        SetFilters(FADocHeader, FADocLine);
                        FAMovementActRep.SetTableView(FADocHeader);
                        FAMovementActRep.SetTableView(FADocLine);
                        FAMovementActRep.Run;
                    end;
                }
                action("FA Movement FA-15")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Movement FA-15';
                    ToolTip = 'View the transfer of fixed assets for installation work. After you post an FA Movement Act, you can use this report to print the posted document.';

                    trigger OnAction()
                    var
                        FADocHeader: Record "FA Document Header";
                        FADocLine: Record "FA Document Line";
                        FAMovementActRep: Report "FA Movement FA-15";
                    begin
                        SetFilters(FADocHeader, FADocLine);
                        FAMovementActRep.SetTableView(FADocHeader);
                        FAMovementActRep.SetTableView(FADocLine);
                        FAMovementActRep.Run;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get;
        FAEmployeeNoVisible := FASetup."Employee No. Mandatory";
    end;

    var
        [InDataSet]
        FAEmployeeNoVisible: Boolean;

    [Scope('OnPrem')]
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    local procedure SetFilters(var FADocHeader: Record "FA Document Header"; var FADocLine: Record "FA Document Line")
    begin
        FADocHeader.Get("Document Type", "Document No.");
        FADocHeader.SetRecFilter;
        FADocLine := Rec;
        FADocLine.SetRecFilter;
    end;
}


page 12472 "Posted FA Writeoff Act"
{
    Caption = 'Posted FA Writeoff Act';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Posted FA Doc. Header";
    SourceTableView = SORTING("Document Type", "No.")
                      WHERE("Document Type" = CONST(Writeoff));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Reason Document No."; "Reason Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ID number of the source document that is the reason for the fixed asset release.';
                }
                field("Reason Document Date"; "Reason Document Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date of the source document that is the reason for the fixed asset release.';
                }
                field("FA Location Code"; "FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field("FA Employee No."; "FA Employee No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the employee number of the person who maintains possession of the fixed asset.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("FA Posting Date"; "FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Posting No."; "Posting No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a posting number to use for the fixed asset act entry.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(WriteoffLines; "Posted FA Writeoff Act Subf")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Act")
            {
                Caption = '&Act';
                action("Co&mments")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Posted FA Comments";
                    RunPageLink = "Document Type" = CONST(Writeoff),
                                  "Document No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Employee Si&gnatures")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Posted Document Signatures";
                    RunPageLink = "Table ID" = CONST(12471),
                                  "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No.");
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Action1210035)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        // CurrPage.WriteoffLines.PAGE.ShowDimensions();
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Comments';
                    Image = ViewComments;

                    trigger OnAction()
                    begin
                        // CurrPage.WriteoffLines.PAGE.ShowComments;
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Write-off for Tax Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Write-off for Tax Ledger';
                    Image = SignUp;
                    ToolTip = 'Prepare to post fixed asset write offs to the tax ledger.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PostedFADocHeader);
                        REPORT.RunModal(REPORT::"Write-off for Tax Ledger", true, true, PostedFADocHeader);
                    end;
                }
                action("VAT Reinstatement")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'VAT Reinstatement';
                    Image = VATStatement;
                    ToolTip = 'View VAT reinstatements.';

                    trigger OnAction()
                    var
                        VATReinstMgt: Codeunit "VAT Reinstatement Management";
                    begin
                        VATReinstMgt.CreateVATReinstFromFAWriteOff("No.");
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
}


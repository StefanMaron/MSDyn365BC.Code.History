page 12480 "Posted FA Movement Act"
{
    Caption = 'Posted FA Movement Act';
    DataCaptionFields = "Document Type", "No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Posted FA Doc. Header";
    SourceTableView = sorting("Document Type", "No.")
                      where("Document Type" = const(Movement));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Reason Document No."; Rec."Reason Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ID number of the source document that is the reason for the fixed asset release.';
                }
                field("Reason Document Date"; Rec."Reason Document Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date of the source document that is the reason for the fixed asset release.';
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field("New FA Location Code"; Rec."New FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a code to register the new location of the fixed asset when it is moved.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(MovementLines; "Posted FA Movement Act Subform")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
                SubPageView = sorting("Document Type", "Document No.", "Line No.");
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
                    RunPageLink = "Document Type" = const(Movement),
                                  "Document No." = field("No."),
                                  "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action("D&imensions")
                {
                    ApplicationArea = Suite;
                    Caption = 'D&imensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Employee Si&gnatures")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    RunObject = Page "Posted Document Signatures";
                    RunPageLink = "Table ID" = const(12471),
                                  "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Cancel FA Location Movement")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Cancel FA Location Movement';
                Image = CancelLine;

                trigger OnAction()
                begin
                    CurrPage.MovementLines.PAGE.CancelMovement();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Cancel FA Location Movement_Promoted"; "Cancel FA Location Movement")
                {
                }
                actionref("Employee Si&gnatures_Promoted"; "Employee Si&gnatures")
                {
                }
            }
        }
    }

    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
}


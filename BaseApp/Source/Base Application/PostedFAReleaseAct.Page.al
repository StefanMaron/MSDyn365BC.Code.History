page 12476 "Posted FA Release Act"
{
    Caption = 'Posted FA Release Act';
    DataCaptionFields = "Document Type", "No.";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Posted FA Doc. Header";
    SourceTableView = SORTING("Document Type", "No.")
                      WHERE("Document Type" = CONST(Release));

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
            part(ReleaseLines; "Posted FA Release Act Subform")
            {
                ApplicationArea = FixedAssets;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
                SubPageView = SORTING("Document Type", "Document No.", "Line No.");
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
                    RunPageLink = "Document Type" = CONST(Release),
                                  "Document No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
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
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

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


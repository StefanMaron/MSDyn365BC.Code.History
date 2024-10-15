page 11799 "No. Series Links"
{
    Caption = 'No. Series Links';
    DataCaptionFields = "Initial No. Series";
    PageType = List;
    SourceTable = "No. Series Link";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of No. Series Enhancements will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    layout
    {
        area(content)
        {
            repeater(Control1220017)
            {
                ShowCaption = false;
                field("Initial No. Series"; "Initial No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of initial number series, to which are setup the related number series.';
                    Visible = false;
                }
                field("Initial No. Series Desc."; "Initial No. Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of initial number series.';
                    Visible = false;
                }
                field("Linked No. Series"; "Linked No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document creating.';
                }
                field("Linked No. Series Desc."; "Linked No. Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of following number series.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document posting.';
                }
                field("Posting No. Series Desc."; "Posting No. Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of following number series for document posting.';
                }
                field("Shipping No. Series"; "Shipping No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document shipping .';
                }
                field("Shipping No. Series Desc."; "Shipping No. Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of shipping number series links.';
                }
                field("Receiving No. Series"; "Receiving No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document receiving wh.';
                }
                field("Receiving No. Series Desc."; "Receiving No. Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of following number series for document posting.';
                }
                field("Shipping Wh. No. Series"; "Shipping Wh. No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document shipping wh.';
                }
                field("Shipping Wh. No. Series Desc."; "Shipping Wh.No.Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of following number series for document posting.';
                }
                field("Receiving Wh. No. Series"; "Receiving Wh. No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the setup of following number series for document receiving .';
                }
                field("Receiving Wh. No. Series Desc."; "Receiving Wh.No.Series Desc. 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of following number series for document posting.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}


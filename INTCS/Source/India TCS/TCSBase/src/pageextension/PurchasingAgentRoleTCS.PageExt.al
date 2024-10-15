pageextension 18815 "Purchasing Agent Role TCS" extends "Purchasing Agent Role Center"
{
    actions
    {
        addlast("India Taxation")
        {
            group("Tax Collected at Source")
            {
                group("Auto Configuration TCS")
                {
                    Caption = 'Auto Configuration';
                    action("TCS Nature of Collection")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'TCS Nature of Collection';
                        Promoted = false;
                        Image = EditList;
                        RunObject = Page "TCS Nature of Collections";
                        ToolTip = 'Specifies the TCS Nature of Collection under which tax has been collected.';
                    }
                }
                group("User Configuration TCS")
                {
                    Caption = 'User Configuration';
                    action("TCS Posting Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'TCS Posting Setup';
                        Promoted = false;
                        Image = EditList;
                        RunObject = Page "TCS Posting Setup";
                        ToolTip = 'Specifies the TCS nature of collection on which TCS is liable to be collected.';
                    }
                    action("T.C.A.N. Nos.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'T.C.A.N. Nos.';
                        Promoted = false;
                        Image = EditList;
                        RunObject = Page "T.C.A.N. Nos.";
                        RunPageMode = Edit;
                        ToolTip = 'T.C.A.N. number is allotted by Income Tax Department to the collector.';
                    }
                    action("TCS Rates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'TCS Rates';
                        Promoted = false;
                        Image = EditList;
                        RunObject = page "Tax Rates";
                        RunPageLink = "Tax Type" = const('TCS');
                        RunPageMode = Edit;
                        ToolTip = 'Specifies the TCS rates for each NOC and assessee type in the TCS rates window.';
                    }
                }
            }
        }
    }
}
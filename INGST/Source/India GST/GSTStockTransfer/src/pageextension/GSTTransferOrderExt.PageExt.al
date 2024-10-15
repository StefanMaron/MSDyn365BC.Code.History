pageextension 18395 "GST Transfer Order Ext" extends "Transfer Order"
{
    layout
    {
        addafter("Entry/Exit Point")
        {
            Field("Time of Removal"; Rec."Time of Removal")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Sepecifies the time of removal.';
            }
            field("Mode of Transport"; Rec."Mode of Transport")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the mode of transport used for transfer.';
            }
            field("Vehicle No."; Rec."Vehicle No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the vehicle no used for transfer.';
            }
            field("Vehicle Type"; Rec."Vehicle Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of vehicle used for transfer.';
            }
            field("LR/RR No."; Rec."LR/RR No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the lorry receipt number.';

            }
            field("LR/RR Date"; Rec."LR/RR Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the lorry receipt date.';
            }
            field("Distance (Km)"; Rec."Distance (Km)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the distance of the transfer route.';
            }
        }
        addafter("Foreign Trade")
        {
            group(GST)
            {
                field("Bill of Entry No."; Rec."Bill Of Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill of entry number. It is a document number which is submitted to custom department .';
                }
                field("Bill of Entry Date"; Rec."Bill Of Entry Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry date defined in bill of entry document.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor number.';
                }
            }
        }
    }
}
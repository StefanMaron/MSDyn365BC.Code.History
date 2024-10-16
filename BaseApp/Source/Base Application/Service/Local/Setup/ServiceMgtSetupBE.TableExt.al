namespace Microsoft.Service.Setup;

tableextension 11306 "Service Mgt. Setup BE" extends "Service Mgt. Setup"
{
    fields
    {
        field(11300; "Jnl. Templ. Serv. Inv."; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Inv.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Serv. Inv. Template Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11301; "Jnl. Templ. Serv. Contr. Inv."; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Contr. Inv.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Serv. Contr. Inv. Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11302; "Jnl. Templ. Serv. Contr. CM"; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. Contr. CM';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Serv. Contr. Cr.M. Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
        field(11303; "Jnl. Templ. Serv. CM"; Code[10])
        {
            Caption = 'Jnl. Templ. Serv. CM';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Serv. Cr. Memo Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
    }
}
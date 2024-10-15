permissionset 1562 "D365 IC, EDIT"
{
    Assignable = true;
    Caption = 'Dyn. 365 Edit Intercompany';

    IncludedPermissionSets = "D365 IC, VIEW";

    Permissions = tabledata "General Ledger Setup" = RIM,
                  tabledata "Handled IC Inbox Jnl. Line" = IMD,
                  tabledata "Handled IC Inbox Purch. Header" = IMD,
                  tabledata "Handled IC Inbox Purch. Line" = IMD,
                  tabledata "Handled IC Inbox Sales Header" = IMD,
                  tabledata "Handled IC Inbox Sales Line" = IMD,
                  tabledata "Handled IC Inbox Trans." = IMD,
                  tabledata "Handled IC Outbox Jnl. Line" = IMD,
                  tabledata "Handled IC Outbox Purch. Hdr" = IMD,
                  tabledata "Handled IC Outbox Purch. Line" = IMD,
                  tabledata "Handled IC Outbox Sales Header" = IMD,
                  tabledata "Handled IC Outbox Sales Line" = IMD,
                  tabledata "Handled IC Outbox Trans." = IMD,
                  tabledata "IC Comment Line" = IMD,
                  tabledata "IC Inbox Jnl. Line" = IMD,
                  tabledata "IC Inbox Purchase Header" = IMD,
                  tabledata "IC Inbox Purchase Line" = IMD,
                  tabledata "IC Inbox Sales Header" = IMD,
                  tabledata "IC Inbox Sales Line" = IMD,
                  tabledata "IC Inbox Transaction" = IMD,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = IMD,
                  tabledata "IC Outbox Jnl. Line" = IMD,
                  tabledata "IC Outbox Purchase Header" = IMD,
                  tabledata "IC Outbox Purchase Line" = IMD,
                  tabledata "IC Outbox Sales Header" = IMD,
                  tabledata "IC Outbox Sales Line" = IMD,
                  tabledata "IC Outbox Transaction" = RIMD;
}

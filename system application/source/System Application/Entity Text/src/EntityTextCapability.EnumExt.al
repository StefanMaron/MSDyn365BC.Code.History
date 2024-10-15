namespace System.Text;
using System.AI;

enumextension 2015 "Entity Text Capability" extends "Copilot Capability"
{
#pragma warning disable AS0099
    // Moved to platform in next major
    value(1; Chat)
    {
        Caption = 'Chat';
    }
#pragma warning restore AS0099

    value(2015; "Entity Text")
    {
        Caption = 'Marketing text suggestions';
    }

}
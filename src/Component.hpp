#pragma once

#include <sdk.hpp>

class SUIComponent :
    public IComponent,
    public CoreEventHandler,
    public PlayerConnectEventHandler
{
private:
    ICore* m_core = nullptr;

public:
    PROVIDE_UID(0x9E7D4B2A1C3F5E8D);

    StringView componentName() const override {
        return "SUI_Virtualizer";
    }

    SemanticVersion componentVersion() const override {
        return SemanticVersion(1, 0, 0, 0);
    }

    void onLoad(ICore* c) override;
    void onInit(IComponentList* components) override;
    void onReady() override;
    void onFree(IComponent* component) override;
    void free() override;
    void reset() override;

    void onTick(Microseconds elapsed, TimePoint now) override;

    void onPlayerDisconnect(IPlayer& player, PeerDisconnectReason reason) override;
};
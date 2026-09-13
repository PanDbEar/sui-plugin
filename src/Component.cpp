#include "Component.hpp"
#include "Core.hpp"

#include <algorithm>

COMPONENT_ENTRY_POINT()
{
    return new SUIComponent();
}

void SUIComponent::onLoad(ICore* c)
{
    m_core = c;

    m_core->getEventDispatcher().addEventHandler(this);

    m_core->getPlayers().getPoolEventDispatcher().addEventHandler(this);
}

void SUIComponent::onInit(IComponentList* components) {}
void SUIComponent::onReady() {}
void SUIComponent::onFree(IComponent* component) {}
void SUIComponent::free() { delete this; }
void SUIComponent::reset() {}

void SUIComponent::onTick(Microseconds elapsed, TimePoint now)
{
    SUICore::ProcessTick(Utils::GetTickCountMs());
}

void SUIComponent::onPlayerDisconnect(IPlayer& player, PeerDisconnectReason reason)
{
    SUICore::CleanupPlayer(player.getID());
}
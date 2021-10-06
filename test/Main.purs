module Test.Main where

import Prelude

import Control.Monad.Free (Free)
import Data.Either (Either(..), fromRight')
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), fromMaybe')
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Class (liftEffect)
import Erl.Data.Binary.IOData (fromBinary)
import Erl.Data.Binary.UTF8 (toBinary)
import Erl.Data.Tuple (tuple4, tuple8)
import Erl.Kernel.Inet (ActiveError(..), ConnectAddress(..), HostAddress(..), Ip4Address(..), Ip6Address(..), IpAddress(..), SocketActive(..), SocketAddress(..), ntoa, ntoa4, ntoa6, parseIpAddress)
import Erl.Kernel.Tcp (TcpMessage(..))
import Erl.Kernel.Tcp as Tcp
import Erl.Kernel.Udp (UdpMessage(..))
import Erl.Kernel.Udp as Udp
import Erl.Process (Process, ProcessM, receive, spawnLink, unsafeRunProcessM, (!))
import Erl.Process.Class (self)
import Erl.Test.EUnit (TestF, runTests, suite, test)
import Erl.Types (Timeout(..))
import Erl.Untagged.Union (class RuntimeType, type (|$|), type (|+|), Nil, RTLiteralAtom, RTOption, RTTuple1, Union, inj, prj)
import Partial.Unsafe (unsafeCrashWith)
import Test.Assert (assertEqual, assertTrue)


main :: Effect Unit
main = void $ runTests do
  tcpTests
  udpTests
  ipTests

data Msg
  = Ready

derive instance eqMsg :: Eq Msg
derive instance genericMsg :: Generic Msg _
instance showMsg :: Show Msg where
  show = genericShow
instance runtimeTypeMsg :: RuntimeType Msg (RTOption (RTTuple1 (RTLiteralAtom "ready")) (RTTuple1 (RTLiteralAtom "accepted")))

type ClientUnion
  = Union |$| Msg |+| TcpMessage |+| Nil
type ServerUnion
  = Union |$| TcpMessage |+| Nil

tcpTests :: Free TestF Unit
tcpTests = do
  suite "tcp tests" do
    test "active listen-connect-accept-message-close test" do
      unsafeRunProcessM
        $ do
            self <- self
            _server <- liftEffect $ spawnLink $ server self
            ready <- receive
            liftEffect $ assertEqual { actual: prj ready, expected: Just Ready }
            client <- unsafeFromRight "connect failed" <$> Tcp.connect (SocketAddr (IpAddress (Ip4 $ Ip4Address $ tuple4 127 0 0 1))) 8080 {} (Timeout 1000)
            _ <- liftEffect $ Tcp.send client $ fromBinary $ toBinary "hello"
            msg <- receive
            _ <- liftEffect $ assertEqual { expected: Just $ Tcp client (toBinary "world"), actual: prj msg }
            close <- receive
            liftEffect $ assertEqual { expected: Just $ Tcp_closed client, actual: prj close }
    test "passive listen-connect-accept-message-close test" do
      unsafeRunProcessM
        $ do
            self <- self
            _server <- liftEffect $ spawnLink $ server self
            ready <- receive
            liftEffect $ assertEqual { actual: prj ready, expected: Just Ready }
            client <- unsafeFromRight "connect failed" <$> Tcp.connect (SocketAddr (IpAddress (Ip4 $ Ip4Address $ tuple4 127 0 0 1))) 8080 { active: Passive } (Timeout 1000)
            liftEffect
              $ do
                  _ <- Tcp.send client $ fromBinary $ toBinary "hello"
                  msg <- unsafeFromRight "recv failed" <$> Tcp.recv client 5 InfiniteTimeout
                  _ <- assertTrue $ msg == toBinary "world"
                  closed <- Tcp.recv client 0 InfiniteTimeout
                  assertTrue $ closed == Left ActiveClosed
    test "passive listen-connect-accept-message-close test via setopts" do
      unsafeRunProcessM
        $ do
            self <- self
            _server <- liftEffect $ spawnLink $ server self
            ready <- receive
            liftEffect $ assertEqual { actual: prj ready, expected: Just Ready }
            client <- unsafeFromRight "connect failed" <$> Tcp.connect (SocketAddr (IpAddress (Ip4 $ Ip4Address $ tuple4 127 0 0 1))) 8080 {} (Timeout 1000)
            liftEffect
              $ do
                  _ <- unsafeFromRight "setopts failed" <$> Tcp.setopts client { active: Passive }
                  _ <- Tcp.send client $ fromBinary $ toBinary "hello"
                  msg <- unsafeFromRight "recv failed" <$> Tcp.recv client 5 InfiniteTimeout
                  _ <- assertTrue $ msg == toBinary "world"
                  closed <- Tcp.recv client 0 InfiniteTimeout
                  assertTrue $ closed == Left ActiveClosed
    test "can do partial receives" do
      unsafeRunProcessM
        $ do
            self <- self
            _server <- liftEffect $ spawnLink $ server self
            ready <- receive
            liftEffect $ assertEqual { actual: prj ready, expected: Just Ready }
            client <- unsafeFromRight "connect failed" <$> Tcp.connect (SocketAddr (IpAddress (Ip4 $ Ip4Address $ tuple4 127 0 0 1))) 8080 { active: Passive } (Timeout 1000)
            liftEffect
              $ do
                  _ <- Tcp.send client $ fromBinary $ toBinary "hello"
                  msg1 <- unsafeFromRight "recv failed" <$> Tcp.recv client 3 InfiniteTimeout
                  _ <- assertTrue $ msg1 == toBinary "wor"
                  msg2 <- unsafeFromRight "recv failed" <$> Tcp.recv client 2 InfiniteTimeout
                  _ <- assertTrue $ msg2 == toBinary "ld"
                  closed <- Tcp.recv client 0 InfiniteTimeout
                  assertTrue $ closed == Left ActiveClosed

  where
  server :: Process ClientUnion -> ProcessM ServerUnion Unit
  server parent = do
    listenSocket <- liftEffect $ unsafeFromRight "listen failed" <$> Tcp.listen 8080 { reuseaddr: true }
    _ <- liftEffect $ parent ! inj Ready
    clientSocket <- unsafeFromRight "accept failed" <$> Tcp.accept listenSocket InfiniteTimeout
    _ <- liftEffect $ Tcp.close listenSocket
    msg <- receive
    liftEffect
      $ do
          _ <- assertEqual { expected: Just $ Tcp clientSocket (toBinary "hello"), actual: prj msg }
          _ <- Tcp.send clientSocket $ fromBinary $ toBinary "world"
          _ <- Tcp.close clientSocket
          pure unit

udpTests :: Free TestF Unit
udpTests = do
  suite "udp tests" do
    test "active message test" do
      unsafeRunProcessM
        $ do
            socket1 <- unsafeFromRight "open failed" <$> Udp.open 8888 { reuseaddr: true }
            socket2 <- unsafeFromRight "open failed" <$> Udp.open 0 {}
            port2 <- liftEffect $ unsafeFromJust "port failed" <$> Udp.port socket2
            _ <- liftEffect $ Udp.send socket2 (Host "localhost") 8888 (fromBinary (toBinary "hello"))
            message <- receive
            liftEffect $ assertEqual { actual: message, expected: Udp socket1 (inj $ Ip4Address (tuple4 127 0 0 1)) port2 (toBinary "hello") }
    test "passive message test" do
      unsafeRunProcessM
        $ ( ( do
                socket1 <- unsafeFromRight "open failed" <$> Udp.open 8888 { reuseaddr: true, active: Passive }
                socket2 <- unsafeFromRight "open failed" <$> Udp.open 0 {}
                liftEffect
                  $ do
                      _ <- Udp.send socket2 (Host "localhost") 8888 (fromBinary (toBinary "hello"))
                      recvData <- unsafeFromRight "recv failed" <$> Udp.recv socket1 InfiniteTimeout
                      let
                        payload = case recvData of
                          Udp.Data _ _ p -> Just p
                          Udp.DataAnc _ _ _ _ -> Nothing
                      assertTrue $ payload == (Just $ toBinary "hello")
            ) ::
              ProcessM UdpMessage Unit
          )
    test "passive message test via setopts" do
      unsafeRunProcessM
        $ ( ( do
                socket1 <- unsafeFromRight "open failed" <$> Udp.open 8888 { reuseaddr: true }
                socket2 <- unsafeFromRight "open failed" <$> Udp.open 0 {}
                liftEffect
                  $ do
                      _ <- unsafeFromRight "setopts failed" <$> Udp.setopts socket1 { active: Passive }
                      _ <- Udp.send socket2 (Host "localhost") 8888 (fromBinary (toBinary "hello"))
                      recvData <- unsafeFromRight "recv failed" <$> Udp.recv socket1 InfiniteTimeout
                      let
                        payload = case recvData of
                          Udp.Data _ _ p -> Just p
                          Udp.DataAnc _ _ _ _ -> Nothing
                      assertTrue $ payload == (Just $ toBinary "hello")
            ) ::
              ProcessM UdpMessage Unit
          )

ipTests :: Free TestF Unit
ipTests = do
  suite "ip tests" do
    test "Can convert valid IPv4 address" do
      let
        expected = Just $ Ip4 $ Ip4Address ip4Addr
        actual = parseIpAddress validIp4Str
      assertEqual {actual, expected}
    test "Can convert valid IPv6 address" do
      let
        expected =  Just $ Ip6 $ Ip6Address ip6Addr
        actual = parseIpAddress validIp6Str
      assertEqual {actual, expected}
    test "Fails on invalid IPv4 address" do
      let
        ipStr = "123.221.0.256"
        expected = Nothing
        actual = parseIpAddress ipStr
      assertEqual {actual, expected}
    test "Fails on invalid IPv6 address" do
      let
        ipStr = "z001:db8:3333:4444:5555:6666:7777:8888"
        expected =  Nothing
        actual = parseIpAddress ipStr
      assertEqual {actual, expected}
    test "Can build string from valid Ip4 address" do
      let
        expected = Just validIp4Str
        actual = ntoa $ Ip4 $ Ip4Address ip4Addr
      assertEqual {actual, expected}
    test "Can build string from valid Ip6 address" do
      let
        expected = Just validIp6Str
        actual = ntoa $ Ip6  $ Ip6Address ip6Addr
      assertEqual {actual, expected}
    test "Can build string from Ip4 tuple" do
      let
        expected = Just validIp4Str
        actual = ntoa4  $ Ip4Address ip4Addr
      assertEqual {actual, expected}
    test "Can build string from Ip6 tuple" do
      let
        expected = Just validIp6Str
        actual = ntoa6 $  Ip6Address ip6Addr
      assertEqual {actual, expected}
  where
    validIp4Str = "123.221.0.255"
    ip4Addr = (tuple4 123 221 0 255)
    validIp6Str =  "2001:db8:3333:4444:5555:6666:7777:8888"
    ip6Addr = (tuple8 8193 3512 13107 17476 21845 26214 30583 34952)


unsafeFromJust :: forall a. String -> Maybe a -> a
unsafeFromJust s = fromMaybe' (\_ -> unsafeCrashWith s)

unsafeFromRight :: forall a b. String -> Either a b -> b
unsafeFromRight s = fromRight' (\_ -> unsafeCrashWith s)

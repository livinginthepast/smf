module PropertiesHelper
  def read_xml
    allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
    allow(shellout).to receive(:stdout).and_return(dnsxml)
    allow(shellout).to receive(:run_command).and_return(nil)
    allow(shellout).to receive(:live_stream).and_return(nil)
    allow(shellout).to receive(:live_stream=).and_return(nil)
    allow(shellout).to receive(:error!).and_return(nil)
  end

  def dnsxml
    File.read('spec/fixtures/dns.xml')
  end
end
